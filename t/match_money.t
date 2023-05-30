#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Get::Article;

my $expected = [
   ["23", 'XAF'],
   ["1200", '€' ],
   ["100.23", '₹'],
   ["1,100,100.203", '$'],
]

is_deeply([ map {Get::Article->get_price($_)} <DATA>], $expected);


done_testing(5);

__DATA__
foo foo foo 23 XAF bar bar bar
foo 1,200€ bar bar b
bar $100.23 foo foo
bar1 foo1 ₹ 100.23 foo bar
Got $1,100,100.203 this morning
 
