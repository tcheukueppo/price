#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Get::Price' ) || print "Bail out!\n";
}

diag( "Testing Get::Price $Get::Price::VERSION, Perl $], $^X" );
