#!/usr/bin/evn perl
use strict;
use warnings;
#use diagnostics;

use Config::YAML;
use Term::Prompt;

my $config_file = 'environments/production.yml';
my $conf = Config::YAML->new(
    config => $config_file,
    output => $config_file,
);

my $prompts = {
    'pages'     => ['x', q{Where are the Markdown files you want Markthrough to publish?}, '', "$ENV{HOME}/pages"],
    'maxlinks'  => ['r', q{How many links should I show in the navigation?}, '', 10, 0, 100],
    'skin'      => ['e', q{Which skin should be your site's default?}, '', 'greypages', qr/(?:greypages|vector|style)/],
};

exit unless prompt('y', 'Begin setting up your Markthrough app?', '', 'y');
foreach my $key (keys %$prompts) {
    my $prompt = $prompts->{$key};
    my $res = prompt($prompt->[0], $prompt->[1], $prompt->[2], $prompt->[3], $prompt->[4], $prompt->[5]);
    $conf->{$key} = $res;
}
$conf->write;
print "OK, done!\n";
