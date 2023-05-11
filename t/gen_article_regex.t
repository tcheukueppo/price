use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use feature qw(say);

use lib './t/utils';
use Util;

my $av = Util::ReadText('./t/contents/example.co');
say Dumper $av;
