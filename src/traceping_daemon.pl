#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);

# Configuración - Adaptada para Docker
my $dsn = "dbi:SQLite:dbname=/data/traceping.sqlite";
my $config_file = '/config/Targets';
my $interval = $ENV{TRACEPING_INTERVAL} || 300;  # 5 minutos por defecto
my $retention_days = $ENV{TRACEPING_RETENTION_DAYS} || 365;  # 1 año por defecto

# Zona horaria desde variable de entorno o por defecto
my $tz = $ENV{TZ} || 'UTC';
$ENV{TZ} = $tz;
POSIX::tzset();

# Cargar librería de Smokeping (ruta en Docker)
use lib '/usr/lib/smokeping';
eval {
    require Smokeping;
    1;
} or do {
    # Si no está disponible, usar método alternativo
    print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Warning: Smokeping library not found, using alternative method\n";
};

# Inicializar base de datos si no existe
init_database();

print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Traceping daemon iniciado (PID: $$)\n";
print "  Config: $config_file\n";
print "  Interval: $interval segundos\n";
print "  Retention: $retention_days días\n";
print "  Timezone: $tz\n";

# Loop principal
while (1) {
    my @targets = load_targets();
    my $count = scalar(@targets);
    print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Ejecutando traceroutes para $count targets...\n";
    
    foreach my $target (@targets) {
        run_traceroute($target);
    }
    
    # Limpiar registros antiguos
    cleanup_old_records();
    
    print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Ciclo completado. Esperando $interval segundos...\n";
    sleep($interval);
}

sub init_database {
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 0, PrintError => 0 });
    if ($dbh) {
        $dbh->do('CREATE TABLE IF NOT EXISTS traceroute_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            target TEXT NOT NULL,
            tracert TEXT,
            timestamp TEXT NOT NULL
        )');
        $dbh->do('CREATE INDEX IF NOT EXISTS idx_target_timestamp ON traceroute_history(target, timestamp)');
        $dbh->disconnect;
    }
}

# Check if an IP is private (RFC1918)
sub is_private_ip {
    my ($ip) = @_;
    return 0 unless defined $ip;
    return 0 if $ip eq '*';
    
    my @parts = split(/\./, $ip);
    return 0 if scalar(@parts) != 4;
    
    # 10.0.0.0/8
    return 1 if ($parts[0] eq '10');
    # 172.16.0.0/12
    return 1 if ($parts[0] eq '172' && $parts[1] >= 16 && $parts[1] <= 31);
    # 192.168.0.0/16
    return 1 if ($parts[0] eq '192' && $parts[1] eq '168');
    # 100.64.0.0/10 (CGNAT)
    return 1 if ($parts[0] eq '100' && $parts[1] >= 64 && $parts[1] <= 127);
    
    return 0;
}

# Extract domain suffix from hop string (e.g. "prs-bb1-link.ip.twelve99.net (62.115.x.x)" -> "twelve99.net")
sub extract_domain {
    my ($hop) = @_;
    return '' unless defined $hop;
    
    # Format: "hostname (IP)" or just "IP" or "*"
    if ($hop =~ /^([^\s]+)\s+\(/) {
        my $hostname = $1;
        # Get last 2 parts of hostname (domain.tld)
        my @parts = split(/\./, $hostname);
        if (scalar(@parts) >= 2) {
            return join('.', @parts[-2..-1]);
        }
    }
    return '';
}

# Extract IP from hop string
sub extract_ip {
    my ($hop) = @_;
    return '' unless defined $hop;
    
    if ($hop =~ /\((\d+\.\d+\.\d+\.\d+)\)/) {
        return $1;
    }
    # Might be just an IP
    if ($hop =~ /^(\d+\.\d+\.\d+\.\d+)$/) {
        return $1;
    }
    return '';
}

# Check if two hops are "similar" - SMART comparison
# Returns 1 if hops should be considered equivalent (no alert)
sub is_similar_hop {
    my ($hop1, $hop2) = @_;
    
    # Both undefined or timeout - consider equivalent
    return 1 if (!defined $hop1 && !defined $hop2);
    return 1 if ((defined $hop1 && $hop1 eq '*') && (defined $hop2 && $hop2 eq '*'));
    
    # One is timeout/undef, other is not - IGNORE (don't trigger alert for timeouts)
    return 1 if (!defined $hop1 || !defined $hop2);
    return 1 if ($hop1 eq '*' || $hop2 eq '*');
    
    # Exact match
    return 1 if ($hop1 eq $hop2);
    
    # Extract IPs
    my $ip1 = extract_ip($hop1);
    my $ip2 = extract_ip($hop2);
    
    # Both are private IPs - consider equivalent (internal routing doesn't matter)
    if ($ip1 && $ip2) {
        return 1 if (is_private_ip($ip1) && is_private_ip($ip2));
    }
    
    # Check domain - if same domain suffix, consider equivalent
    my $domain1 = extract_domain($hop1);
    my $domain2 = extract_domain($hop2);
    
    if ($domain1 && $domain2 && $domain1 eq $domain2) {
        return 1;  # Same ISP, just different router
    }
    
    # Both public IPs without hostnames - check same /16
    if ($ip1 && $ip2 && !$domain1 && !$domain2) {
        my @parts1 = split(/\./, $ip1);
        my @parts2 = split(/\./, $ip2);
        return 1 if ($parts1[0] eq $parts2[0] && $parts1[1] eq $parts2[1]);
    }
    
    return 0;
}

sub load_targets {
    my @targets;
    
    if (defined &Smokeping::load_cfg) {
        # Método con librería Smokeping
        Smokeping::load_cfg($config_file, 1);
        
        foreach my $group (keys %{$Smokeping::cfg->{'Targets'}}) {
            next unless ref $Smokeping::cfg->{'Targets'}->{$group};
            my $group_hr = $Smokeping::cfg->{'Targets'}->{$group};
            
            foreach my $server (keys %{$group_hr}) {
                next unless ref $group_hr->{$server} && ref $group_hr->{$server} eq 'HASH';
                my $target = "${group}.${server}";
                
                if (!exists $group_hr->{$server}->{'host'}) {
                    foreach my $third (keys %{$group_hr->{$server}}) {
                        next if ref $group_hr->{$server}->{$third} ne 'HASH';
                        next if !exists $group_hr->{$server}->{$third}->{'host'};
                        push @targets, { 
                            target => "${target}.${third}", 
                            host => $group_hr->{$server}->{$third}->{'host'},
                            traceroute_mode => $group_hr->{$server}->{$third}->{'traceroute_mode'} || 'icmp'
                        };
                    }
                } else {
                    push @targets, { 
                        target => $target, 
                        host => $group_hr->{$server}->{'host'},
                        traceroute_mode => $group_hr->{$server}->{'traceroute_mode'} || 'icmp'
                    };
                }
            }
        }
    } else {
        # Método alternativo: parsear archivo de configuración directamente
        if (open(my $fh, '<', $config_file)) {
            my $current_group = '';
            my $current_server = '';
            while (my $line = <$fh>) {
                chomp $line;
                $line =~ s/#.*$//;  # Eliminar comentarios
                $line =~ s/^\s+|\s+$//g;  # Trim
                next if $line eq '';
                
                if ($line =~ /^\+(\w+)/) {
                    $current_group = $1;
                } elsif ($line =~ /^\+\+(\w+)/) {
                    $current_server = $1;
                } elsif ($line =~ /^\+\+\+(\w+)/) {
                    my $third = $1;
                    # Buscar host en las siguientes líneas
                    my $host = '';
                    while (my $next_line = <$fh>) {
                        chomp $next_line;
                        $next_line =~ s/#.*$//;
                        $next_line =~ s/^\s+|\s+$//g;
                        if ($next_line =~ /^host\s*=\s*(.+)$/i) {
                            $host = $1;
                            last;
                        } elsif ($next_line =~ /^\+/) {
                            seek($fh, -length($next_line) - 1, 1);
                            last;
                        }
                    }
                    if ($host) {
                        push @targets, {
                            target => "${current_group}.${current_server}.${third}",
                            host => $host
                        };
                    }
                } elsif ($line =~ /^host\s*=\s*(.+)$/i && $current_group && $current_server) {
                    push @targets, {
                        target => "${current_group}.${current_server}",
                        host => $1
                    };
                }
            }
            close($fh);
        }
    }
    
    return @targets;
}

sub run_traceroute {
    my ($target) = @_;
    my $host = $target->{host};
    my $name = $target->{target};
    my $mode = $target->{traceroute_mode} || 'icmp';  # Default to ICMP
    
    # Build traceroute command based on mode
    my $cmd;
    if ($mode eq 'tcp') {
        # TCP traceroute (uses tcptraceroute binary)
        $cmd = "/usr/bin/timeout 15s /usr/bin/tcptraceroute -w 1 -q 1 -m 20 $host 2>&1";
    } elsif ($mode eq 'udp') {
        # Standard UDP traceroute
        $cmd = "/usr/bin/timeout 15s /usr/bin/traceroute -w 1 -q 1 -m 20 $host 2>&1";
    } else {
        # ICMP traceroute (default, most compatible)
        $cmd = "/usr/bin/timeout 15s /usr/bin/traceroute -I -w 1 -q 1 -m 20 $host 2>&1";
    }
    
    my $result = `$cmd`;
    my $exit_code = $? >> 8;

    # Si timeout mata el proceso, el exit code suele ser 124 o 137
    if ($exit_code == 124 || $exit_code == 137) {
        print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - TIMEOUT WARNING: Traceroute to $name ($host) took too long and was killed.\n";
        $result = ""; # No guardar resultado parcial corrupto
    }

    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 0, PrintError => 0 });
    if ($dbh) {
        # 1. Recuperar el último traceroute
        my $last_tracert = "";
        my $sth_check = $dbh->prepare('SELECT tracert FROM traceroute_history WHERE target = ? ORDER BY timestamp DESC LIMIT 1');
        $sth_check->execute($name);
        if (my $row = $sth_check->fetchrow_hashref) {
            $last_tracert = $row->{tracert};
        }
        
        # 2. Insertar el nuevo
        my $sth = $dbh->prepare('INSERT INTO traceroute_history (target, tracert, timestamp) VALUES (?, ?, ?)');
        $sth->execute($name, $result, $timestamp);
        
        # 3. Detectar cambios (Si hay config de telegram y habia ruta previa)
        if ($ENV{'TELEGRAM_BOT_TOKEN'} && $last_tracert && $last_tracert ne $result) {
            # Limpiar timestamps/tiempos del output para evitar falsos positivos por jitter
            my $clean_old = extract_hops($last_tracert);
            my $clean_new = extract_hops($result);
            
            if ($clean_old ne $clean_new) {
                # PROVIDER-SET COMPARISON: Only alert if the SET of providers changes
                # This ignores hop shifting and internal balancing
                my @hops_old = split(/,/, $clean_old);
                my @hops_new = split(/,/, $clean_new);
                
                # Extract unique provider domains from each route
                my %providers_old;
                my %providers_new;
                
                foreach my $hop (@hops_old) {
                    my $domain = extract_domain($hop);
                    $providers_old{$domain} = 1 if $domain;
                }
                
                foreach my $hop (@hops_new) {
                    my $domain = extract_domain($hop);
                    $providers_new{$domain} = 1 if $domain;
                }
                
                # Find providers that appeared or disappeared
                my @disappeared;
                my @appeared;
                
                foreach my $p (keys %providers_old) {
                    push @disappeared, $p unless exists $providers_new{$p};
                }
                
                foreach my $p (keys %providers_new) {
                    push @appeared, $p unless exists $providers_old{$p};
                }
                
                # Only alert if providers changed (ignore if same set)
                if (@disappeared || @appeared) {
                    my $change_summary = "";
                    $change_summary .= "REMOVED: " . join(", ", @disappeared) . " | " if @disappeared;
                    $change_summary .= "ADDED: " . join(", ", @appeared) if @appeared;
                    
                    print "Provider change detected for $name: $change_summary\n";
                    system("/usr/share/webapps/smokeping/telegram_notify.pl", "Route Change Detected", $name, "", "", $host, "$clean_old|$clean_new|$change_summary");
                }
            }
        }
        
        $dbh->disconnect;
    }
}

# Helper para extraer solo los saltos (IPs) y ignorar tiempos
sub extract_hops {
    my $trace = shift;
    my @hops;
    foreach my $line (split /\n/, $trace) {
        if ($line =~ /^\s*(\d+)\s+(.+?)\s+\d+\.\d+ ms/) {
            push @hops, "$1: $2";
        }
    }
    return join(",", @hops);
}

sub cleanup_old_records {
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 0, PrintError => 0 });
    if ($dbh) {
        my $cutoff = strftime("%Y-%m-%d %H:%M:%S", localtime(time - ($retention_days * 86400)));
        my $sth = $dbh->prepare('DELETE FROM traceroute_history WHERE timestamp < ?');
        $sth->execute($cutoff);
        $dbh->disconnect;
    }
}
