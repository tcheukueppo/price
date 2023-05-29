#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Get::Article;

my @samples = (
   ['MARTHA', 'MARHTA'],
   ['DIXON', 'DICKSONX'],
   ['JELLYFISH', 'SMELLYFISH'],
);

is_deeply([ map { Get::Article::_jaro($_->[0], $_->[1]) } @samples ], [0.9444444444, 0.7666666667, 0.8962962963], "does jaro works?");

done_testing(1);
