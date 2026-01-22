#!/usr/bin/env perl

use strict;
use warnings;
use IO::Socket::INET;

my $port = $ENV{TRACEPING_PORT} || 9000;
my $server = IO::Socket::INET->new(
    LocalPort => $port,
    Type => SOCK_STREAM,
    Reuse => 1,
    Listen => 10
) or die "Cannot create socket: $!";

print "TracePing server listening on port $port\n";

while (my $client = $server->accept()) {
    my $request = '';
    while (<$client>) {
        $request .= $_;
        last if $_ =~ /^\r?\n$/;
    }

    if ($request =~ /GET\s+(\S+)\s+HTTP/) {
        my $path = $1;
        my $query = '';
        if ($path =~ /\?(.+)/) {
            $query = $1;
            $path =~ s/\?.*//;
        }

        if ($path =~ /traceping\.cgi/) {
            my $script_path = '/usr/share/webapps/smokeping/traceping.cgi.pl';
            if (-f $script_path) {
                local $ENV{REQUEST_METHOD} = 'GET';
                local $ENV{QUERY_STRING} = $query;
                my $output = `REQUEST_METHOD=GET QUERY_STRING="$query" /usr/bin/perl $script_path 2>&1`;
                print $client "HTTP/1.0 200 OK\r\n";
                print $client "Content-Type: text/html\r\n\r\n";
                print $client $output;
            } else {
                print $client "HTTP/1.0 500 Internal Server Error\r\n\r\n";
                print $client 'Script not found';
            }
        } else {
            print $client "HTTP/1.0 404 Not Found\r\n\r\n";
            print $client 'Not Found';
        }
    }
    close $client;
}
