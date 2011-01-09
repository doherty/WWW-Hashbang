use strict;
use warnings;
use utf8;
use Test::More 0.88 tests => 1;

my $builder = Test::More->builder;
binmode $builder->output,         ':utf8';
binmode $builder->failure_output, ':utf8';
binmode $builder->todo_output,    ':utf8';

# the order is important
use WWW::Hashbang;
use Dancer::Test;

my $avar = "Ævar Arnfjörð Bjarmason</p>";
response_content_like(['GET' => '/page-one'], qr/\Q$avar\E/, 'Unicode comes through unscathed');
