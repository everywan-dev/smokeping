#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use POSIX qw(strftime);

# Configuration - Adapted for Docker
my $dsn = "dbi:SQLite:dbname=/data/traceping.sqlite";
my $targets_file = '/config/Targets';  # Targets file location
my $interval = $ENV{TRACEPING_INTERVAL} || 300;  # 5 minutes default
my $retention_days = $ENV{TRACEPING_RETENTION_DAYS} || 365;  # 1 year default

# Timezone from env or default UTC
my $tz = $ENV{TZ} || 'UTC';
$ENV{TZ} = $tz;
POSIX::tzset();

# Initialize database if missing
init_database();

print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Traceping daemon started (PID: $$)\n";
print "  Targets file: $targets_file\n";
print "  Interval: $interval seconds\n";
print "  Retention: $retention_days days\n";
print "  Timezone: $tz\n";

# Main Loop
while (1) {
    my @targets = load_targets();
    my $count = scalar(@targets);
    print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Running traceroutes for $count targets...\n";
    
    foreach my $target (@targets) {
        run_traceroute($target);
    }
    
    # Clean old records
    cleanup_old_records();
    
    print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - Cycle completed. Waiting $interval seconds...\n";
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

sub load_targets {
    my @targets;
    
    # Directly parse Targets file
    if (open(my $fh, '<', $targets_file)) {
        my $current_group = '';
        my $current_server = '';
        my $pending_host = '';
        
        while (my $line = <$fh>) {
            chomp $line;
            $line =~ s/#.*$//;  # Remove comments
            $line =~ s/^\s+|\s+$//g;  # Trim
            next if $line eq '';
            next if $line =~ /^\*\*\*/;  # Ignore *** sections
            next if $line =~ /^(probe|menu|title|remark)\s*=/i;  # Ignore metadata
            
            # Detect groups: +GroupName
            if ($line =~ /^\+([A-Za-z0-9_]+)\s*$/) {
                $current_group = $1;
                $current_server = '';
                next;
            }
            
            # Detect servers: ++ServerName
            if ($line =~ /^\+\+([A-Za-z0-9_]+)\s*$/) {
                $current_server = $1;
                next;
            }
            
            # Detect host = value
            if ($line =~ /^host\s*=\s*(.+)$/i) {
                my $host = $1;
                $host =~ s/^\s+|\s+$//g;
                
                if ($current_group && $current_server && $host) {
                    push @targets, {
                        target => "${current_group}.${current_server}",
                        host => $host
                    };
                }
                next;
            }
        }
        close($fh);
    } else {
        print strftime("%Y-%m-%d %H:%M:%S", localtime) . " - ERROR: Could not open $targets_file: $!\n";
    }
    
    return @targets;
}

sub run_traceroute {
    my ($target) = @_;
    my $host = $target->{host};
    my $name = $target->{target};
    
    # Run traceroute with fast options (max 15 hops)
    my $result = `/usr/bin/traceroute -w 1 -q 1 -m 15 $host 2>&1`;
    
    # Save to DB with local time
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 0, PrintError => 0 });
    if ($dbh) {
        my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
        my $sth = $dbh->prepare('INSERT INTO traceroute_history (target, tracert, timestamp) VALUES (?, ?, ?)');
        $sth->execute($name, $result, $timestamp);
        $dbh->disconnect;
    }
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
