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
my $date_filter = $cgi->param('date');      # format: YYYY-MM-DD
my $hour_filter = $cgi->param('hour');      # format: HH (00-23)
my $limit = $cgi->param('limit') || 20;     # result limit

# Validate target
unless ($target && $target =~ /^[a-zA-Z0-9._-]+$/) {
    print 'Invalid target parameter';
    exit 1;
}

# Validate limit
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
    return 'Waiting for traceroute data...' unless $dbh;
    my $sth = $dbh->prepare('SELECT tracert FROM traceroute_history WHERE target=? ORDER BY timestamp DESC LIMIT 1');
    return 'Database query error: ' . $dbh->errstr unless $sth;
    $sth->execute($target);
    my $result = $sth->fetchrow_array;
    $sth->finish;
    $dbh->disconnect;
    return $result || 'No traceroute data available.';
}

sub get_traceroute_history {
    my ($target, $date_filter, $hour_filter, $limit) = @_;
    my $dbh = DBI->connect($dsn, $db_username, $db_password, { RaiseError => 0, PrintError => 0 });
    return '<p style="color:#dc3545;">Database connection error</p>' unless $dbh;
    
    my $html = '';
    my $sth;
    my $info = '';
    
    # Build query based on filters
    if ($date_filter && $date_filter =~ /^\d{4}-\d{2}-\d{2}$/) {
        if ($hour_filter && $hour_filter =~ /^\d{1,2}$/) {
            # Filter by date and time
            my $hour_start = sprintf("%02d:00:00", $hour_filter);
            my $hour_end = sprintf("%02d:59:59", $hour_filter);
            $sth = $dbh->prepare("SELECT tracert, timestamp FROM traceroute_history WHERE target=? AND date(timestamp)=? AND time(timestamp) BETWEEN ? AND ? ORDER BY timestamp DESC LIMIT ?");
            $sth->execute($target, $date_filter, $hour_start, $hour_end, $limit);
            $info = "Results for $date_filter at $hour_filter:xx";
        } else {
            # Date filter only
            $sth = $dbh->prepare("SELECT tracert, timestamp FROM traceroute_history WHERE target=? AND date(timestamp)=? ORDER BY timestamp DESC LIMIT ?");
            $sth->execute($target, $date_filter, $limit);
            $info = "Results for $date_filter";
        }
    } else {
        # No filter - latest records
        $sth = $dbh->prepare('SELECT tracert, timestamp FROM traceroute_history WHERE target=? ORDER BY timestamp DESC LIMIT ?');
        $sth->execute($target, $limit);
        $info = "Latest records";
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
        $html = '<p style="color:#5f6368;font-size:12px;text-align:center;">No history available for this date/time.</p>';
    } else {
        $html = "<p style='color:#5f6368;font-size:11px;margin-bottom:10px;'>$info ($count records)</p>" . $html;
    }
    
    $dbh->disconnect;
    return $html;
}
