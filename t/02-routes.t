use strict;
use warnings;
use Test::More 0.88;
my $tests = 0;

# the order is important
use WWW::Hashbang;
use Dancer::Test;

my @reqs = qw(/home /page-one /page-one/subpage /page-two /Hashbang.pm);
foreach my $req (@reqs) {
    route_exists(       ['GET' => $req],        "a route handler is defined for $req");
    $tests++;
    response_status_is( ['GET' => $req], 200,   "response status is 200 for $req");
    $tests++;
}

my @redirs = qw(/ /Hashbang.pm/src);
foreach my $req (@redirs) {
    route_exists(       ['GET' => $req],        "a route handler is defined for $req");
    $tests++;
    response_status_is( ['GET' => $req], 302,   "response status is 302 for $req");
    $tests++;
}
done_testing $tests;
