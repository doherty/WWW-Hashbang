use strict;
use warnings;
#use diagnostics;

package Markthrough::Admin;
# ABSTRACT: provides admin pages to Markthrough

use Dancer ':syntax';
prefix '/admin';

get '/' => sub {
    return 'test';
};

true;

__END__
