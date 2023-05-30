#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
   use_ok('Get::Article') || print "Bail out!\n";
}

diag("Testing Get::Article $Get::Article::VERSION, Perl $], $^X");
