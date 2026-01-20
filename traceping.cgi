#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBD::SQLite;
use CGI qw(:standard);

my $dsn = "dbi:SQLite:dbname=/data/traceping.sqlite";
my $db_username = '';
my $db_password = '';

print "Content-Type: text/html\r\n\r\n";

my $cgi = CGI->new;
my $target = $cgi->param('target');
my $history = $cgi->param('history');
my $date_filter = $cgi->param('date');      # formato: YYYY-MM-DD
my $hour_filter = $cgi->param('hour');      # formato: HH (00-23)
my $limit = $cgi->param('limit') || 20;     # límite de resultados

# Validate target
unless ($target && $target =~ /^[a-zA-Z0-9._-]+$/) {
    print 'Invalid target parameter';
    exit 1;
}

# Validar límite
$limit = 50 if $limit > 100;
$limit = 10 if $limit < 5;

if ($history) {
    print get_traceroute_history($target, $date_filter, $hour_filter, $limit);
} else {
    print '<div id="traceroute"><pre style="width: 900px; overflow: auto;">';
    print get_traceroute($target);
    print '</pre></div>';
}

sub get_traceroute {
    my ($target) = @_;
    my $dbh = DBI->connect($dsn, $db_username, $db_password, { RaiseError => 0, PrintError => 0 });
    return 'Error de conexión a base de datos' unless $dbh;
    my $sth = $dbh->prepare('SELECT tracert FROM traceroute_history WHERE target=? ORDER BY timestamp DESC LIMIT 1');
    $sth->execute($target);
    my $result = $sth->fetchrow_array;
    $dbh->disconnect;
    return $result || 'Sin datos de traceroute disponibles.';
}

sub get_traceroute_history {
    my ($target, $date_filter, $hour_filter, $limit) = @_;
    my $dbh = DBI->connect($dsn, $db_username, $db_password, { RaiseError => 0, PrintError => 0 });
    return '<p style="color:#dc3545;">Error de conexión a base de datos</p>' unless $dbh;
    
    my $html = '';
    my $sth;
    my $info = '';
    
    # Construir query según filtros
    if ($date_filter && $date_filter =~ /^\d{4}-\d{2}-\d{2}$/) {
        if ($hour_filter && $hour_filter =~ /^\d{1,2}$/) {
            # Filtro por fecha y hora
            my $hour_start = sprintf("%02d:00:00", $hour_filter);
            my $hour_end = sprintf("%02d:59:59", $hour_filter);
            $sth = $dbh->prepare("SELECT tracert, timestamp FROM traceroute_history WHERE target=? AND date(timestamp)=? AND time(timestamp) BETWEEN ? AND ? ORDER BY timestamp DESC LIMIT ?");
            $sth->execute($target, $date_filter, $hour_start, $hour_end, $limit);
            $info = "Resultados para $date_filter a las $hour_filter:xx";
        } else {
            # Solo filtro por fecha
            $sth = $dbh->prepare("SELECT tracert, timestamp FROM traceroute_history WHERE target=? AND date(timestamp)=? ORDER BY timestamp DESC LIMIT ?");
            $sth->execute($target, $date_filter, $limit);
            $info = "Resultados para $date_filter";
        }
    } else {
        # Sin filtro - últimos registros
        $sth = $dbh->prepare('SELECT tracert, timestamp FROM traceroute_history WHERE target=? ORDER BY timestamp DESC LIMIT ?');
        $sth->execute($target, $limit);
        $info = "Últimos registros";
    }
    
    my $count = 0;
    while (my ($tracert, $timestamp) = $sth->fetchrow_array) {
        $count++;
        my $open = $count == 1 ? 'open' : '';
        $html .= "<details $open style='margin:4px 0;'>";
        $html .= "<summary style='cursor:pointer;padding:8px 12px;background:#f1f3f4;border:1px solid #dadce0;border-radius:4px;font-size:12px;color:#202124;'>";
        $html .= "<strong>$timestamp</strong></summary>";
        $html .= "<pre style='margin:8px 0 0 0;background:#1e1e1e;color:#d4d4d4;padding:12px;border-radius:4px;font-size:11px;line-height:1.4;overflow-x:auto;'>$tracert</pre>";
        $html .= "</details>";
    }
    
    if ($count == 0) {
        $html = '<p style="color:#5f6368;font-size:12px;text-align:center;">Sin historial disponible para esta fecha/hora.</p>';
    } else {
        $html = "<p style='color:#5f6368;font-size:11px;margin-bottom:10px;'>$info ($count registros)</p>" . $html;
    }
    
    $dbh->disconnect;
    return $html;
}
