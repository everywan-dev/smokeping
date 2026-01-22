#!/bin/sh
export REQUEST_METHOD="${REQUEST_METHOD:-GET}"
export QUERY_STRING="$QUERY_STRING"
export PATH_INFO="$PATH_INFO"
export CONTENT_TYPE="$CONTENT_TYPE"
export CONTENT_LENGTH="$CONTENT_LENGTH"
exec /usr/bin/perl -T /usr/share/webapps/smokeping/traceping.cgi.pl
