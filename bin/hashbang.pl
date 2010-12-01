#!/usr/bin/env perl
use strict;
use warnings;
use Dancer;
use lib path(dirname(__FILE__), 'lib');
load_app 'WWW::Hashbang';
dance;
