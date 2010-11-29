use strict;
use warnings;
#use diagnostics;

package WWW::Hashbang::Plugin::Admin;
# ABSTRACT: provides admin pages to WWW::Hashbang

use Dancer ':syntax';
prefix '/admin';

get '/' => sub {
    return 'test';
};

true;

__END__
