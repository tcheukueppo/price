package Get::Article::Exchange;

use strict;
use warnings;
use utf8;

no warnings 'utf8';
use feature qw(say);

use Mojo::URL;
use Mojo::UserAgent;

sub new {
   bless {
      ua => $_[1] // Mojo::UserAgent->new,
      url => Mojo::URL->new("https://www.xe.com/currencyconverter/"),
   }, $_[0];
}

sub convert {
   my ($self, $amount, $from, $to) = @_;
   # ...
}
