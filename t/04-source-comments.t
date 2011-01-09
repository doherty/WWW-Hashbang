use strict;
use warnings;
use utf8;
use Test::More 0.88 tests => 2;

use HTML::Entities;
# the order is important
use WWW::Hashbang;
use Dancer::Test;

my $comment = '<!--HTML comments-->...';
response_content_unlike(['GET' => '/page-two/src'], qr/\Q$comment\E/, 'Comments appear in the source view properly');
my $htmlcomment = encode_entities($comment);
response_content_like  (['GET' => '/page-two/src'], qr/\Q$htmlcomment\E/, 'Comments appear in the source view properly');
