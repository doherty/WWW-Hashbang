use strict;
use warnings;
use Test::More 0.75;
my $tests = 0;

# the order is important
use Markthrough;
use Dancer::Test;

my @reqs = qw(/home /test /test/one /test/one/two /Markthrough.pm);
foreach my $req (@reqs) {
    route_exists(       [GET => $req],          "a route handler is defined for $req");
    response_status_is( ['GET' => $req], 200,   "response status is 200 for $req");
    $tests += 2;
}

my @redirs = qw(/);
foreach my $req (@redirs) {
    route_exists(       [GET => $req],          "a route handler is defined for $req");
    response_status_is( ['GET' => $req], 302,   "response status is 302 for $req");
    $tests += 2;
}
done_testing $tests;
