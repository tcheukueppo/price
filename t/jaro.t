#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Get::Article;

my @samples = (['MARTHA', 'MARHTA'], ['DIXON', 'DICKSONX'], ['JELLYFISH', 'SMELLYFISH'],);

is_deeply([map { Get::Article::_jaro($_->[0], $_->[1]) } @samples],
          [0.944444444444445, 0.766666666666667, 0.896296296296296],
          "does jaro works?");

done_testing(2);
