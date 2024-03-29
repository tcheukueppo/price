#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use utf8;

use_ok('Get::Article') or print "Bail out!\n";

my @confession = qw(lùvù lôvés kùéppô);

is_deeply([map { Get::Article::_nfkd_normalize($_) } @confession], ['luvu', 'loves', 'kueppo']);

done_testing(2);
