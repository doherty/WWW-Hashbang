use strict;
use warnings;
use Test::More 0.75;

# the order is important
use Markthrough;
use Dancer::Test;

my @reqs = qw(/home /test /test/one /test/one/two);
plan tests => scalar @reqs * 2;
foreach my $req (@reqs) {
    route_exists(       [GET => $req],          "a route handler is defined for $req");
    response_status_is( ['GET' => $req], 200,   "response status is 200 for $req");
}
