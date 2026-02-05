#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use HTTP::Tiny;
use JSON::PP;
use DBI;
use POSIX qw(strftime);
use Encode qw(encode_utf8 decode_utf8);

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

# Configuration from Environment
my $BOT_TOKEN = $ENV{'TELEGRAM_BOT_TOKEN'};
my $CHAT_ID   = $ENV{'TELEGRAM_CHAT_ID'};

# If no Telegram config, exit silently
exit 0 unless ($BOT_TOKEN && $CHAT_ID);

# Arguments from Smokeping Alert
# alertname, target, losspattern, rtt, hostname
my $alertname = $ARGV[0] // "Unknown Alert";
my $target    = $ARGV[1] // "Unknown Target";
my $loss      = $ARGV[2] // "";
my $rtt       = $ARGV[3] // "";
my $hostname  = $ARGV[4] // "";
my $extra_msg = $ARGV[5] // ""; # Custom message (e.g. from route change)

# Clean up Target Name (remove unnecessary ++ signs if present)
$target =~ s/^\++//;

# Get Traceroute Info
my $traceroute_info = "";
my $last_updated = "";
my $db_path = "/opt/traceroute_history/traceroute_history.db";

if (-e $db_path) {
    eval {
        my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { RaiseError => 1, AutoCommit => 1 });
        # Get the MOST RECENT trace for this target (or similar name)
        # We try exact match first, then partial
        my $sth = $dbh->prepare("SELECT path, timestamp FROM traceroutes WHERE target = ? ORDER BY timestamp DESC LIMIT 1");
        $sth->execute($target);
        my $row = $sth->fetchrow_hashref;
        
        # If not found, try flexible matching (Smokeping target names might differ slightly)
        unless ($row) {
             # Remove spaces or underscores
             my $clean_target = $target;
             $clean_target =~ s/[_ ]/%/g;
             $sth = $dbh->prepare("SELECT path, timestamp FROM traceroutes WHERE target LIKE ? ORDER BY timestamp DESC LIMIT 1");
             $sth->execute('%' . $clean_target . '%');
             $row = $sth->fetchrow_hashref;
        }

        if ($row) {
            my $raw_path = $row->{path};
            $last_updated = strftime("%Y-%m-%d %H:%M:%S", localtime($row->{timestamp}));
            
            # Format route: Decode JSON to make it pretty
            my $hops = decode_json($raw_path);
            if (ref $hops eq 'ARRAY') {
                $traceroute_info .= "\n<b>🛣️ Last Known Route ($last_updated):</b>\n<pre>";
                foreach my $hop (@$hops) {
                    my $id = $hop->{id} // "?";
                    my $ip = $hop->{ip} // "*";
                    $traceroute_info .= "$id. $ip\n";
                }
                $traceroute_info .= "</pre>";
            }
        }
    };
    if ($@) {
        # Silent fail on DB error, just don't add trace info
        # warn "DB Error: $@";
    }
}

# Construct Message (HTML format)
my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
# Determine Status and Header
my $status_emoji = "⚠️";
my $status_text  = "WARNING";

if ($alertname =~ /bigloss/i || $loss =~ /100%/) {
    $status_emoji = "🔴";
    $status_text  = "CRITICAL ALERT";
} elsif ($alertname =~ /rtt/i || $alertname =~ /someloss/i) {
    $status_emoji = "⚠️";
    $status_text  = "WARNING";
}

if ($alertname =~ /clear/i) {
    $status_emoji = "🟢";
    $status_text  = "RECOVERY";
}

my $message = "$status_emoji <b>$status_text</b>\n\n";
$message .= "<b>Target:</b> $target\n";
$message .= "<b>Alert:</b> $alertname\n";
$message .= "<b>Time:</b> $timestamp\n";

if ($loss) {
    $message .= "<b>Loss Analysis:</b> $loss\n";
}
if ($rtt) {
    $message .= "<b>Latency:</b> $rtt\n";
}
if ($extra_msg) {
    # Check if it's a Route Change (format: Old|New)
    if ($extra_msg =~ /\|/) {
        my ($old_raw, $new_raw) = split(/\|/, $extra_msg);
        
        $message .= "<b>🛣️ Route Change Detected:</b>\n";
        
        my @old_hops = split(/,/, $old_raw);
        my @new_hops = split(/,/, $new_raw);
        my $max_hops = scalar(@old_hops) > scalar(@new_hops) ? scalar(@old_hops) : scalar(@new_hops);
        
        $message .= "<pre>";
        $message .= sprintf("%-3s %-15s %-15s\n", "#", "Old IP", "New IP");
        $message .= "----------------------------------\n";
        
        for my $i (0 .. $max_hops-1) {
            my $o_hop = $old_hops[$i] // "";
            my $n_hop = $new_hops[$i] // "";
            
            # Limpiar formato "ID: IP" a solo IP para que quepa
            $o_hop =~ s/^\d+:\s*//;
            $n_hop =~ s/^\d+:\s*//;
            
            # Cortar si es muy largo
            $o_hop = substr($o_hop, 0, 15);
            $n_hop = substr($n_hop, 0, 15);
            
            my $marker = ($o_hop eq $n_hop) ? " " : "!";
            $message .= sprintf("%-3s %-15s %-15s %s\n", $i+1, $o_hop, $n_hop, $marker);
        }
        $message .= "</pre>\n";
    } else {
        $message .= "<b>Note:</b> $extra_msg\n";
    }
}

$message .= $traceroute_info if $traceroute_info;

$message .= "\n<a href='http://$hostname/smokeping/?target=$target'>View in SmokePing</a>" if $hostname;

# Send to Telegram
my $ua = HTTP::Tiny->new(timeout => 10);
my $response = $ua->post(
    "https://api.telegram.org/bot$BOT_TOKEN/sendMessage",
    {
        headers => { 'Content-Type' => 'application/json; charset=utf-8' },
        content => encode_utf8(encode_json({
            chat_id => $CHAT_ID,
            text    => $message,
            parse_mode => 'HTML',
            disable_web_page_preview => 1
        }))
    }
);

if ($response->{success}) {
    # print "Message sent.\n";
} else {
    # print "Failed to send: $response->{status} $response->{reason}\n";
}
