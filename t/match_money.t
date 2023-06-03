#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Get::Article;

my $expected = [
                ["23",            'XAF', 0], ["1,200",           '€', 0],
                ["100.23",        '$',   1], ["100.23",          '₹', 1],
                ["1,100,100.203", '$',   1], ['12 000 000.1203', '$', 1]
               ];

is_deeply([map { Get::Article::_get_price($_) } <DATA>], $expected);

done_testing(1);

__DATA__
foo foo foo 23 XAF barbar foobar
foo 1,200€ bar bar b
bar $100.23 foo foo
bar1 foo1 ₹ 100.23 foo bar
Got $1,100,100.203 this morning
Hey you bitch, fuck me and get some $12 000 000.1203
