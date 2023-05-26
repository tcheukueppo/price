package Get::Article::Exchange;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use POSIX;
use Mojo::URL;
use Mojo::UserAgent;

use Get::Article::Currency;

my $codes = map { $_ => 1 } @Get::Article::Currency::CODES;
my $sym   = $Get::Article::Currency::SYMBOLS;

sub new {
   my $url = Mojo::URL
     ->new
     ->scheme('https')
     ->host('fxds-public-exchange-rates-api.oanda.com')
     ->path('/cc-api/currencies');

   bless {
          ua  => $_[1],
          url => $url
         },
     $_[0];
}

sub convert {
   my ($self, $amount) = (shift, shift);

   $_ = exists $codes{uc $_} ? uc $_ : exists $sym->{$_} ? $sym->{$_}[0] : return foreach @_;

   my $date = POSIX::strftime('%Y-%m-%d', localtime(time));
   $self->{url}->query(
                       data_type => 'general_currency_pair',
                       base      => $_[0],
                       quote     => $_[1],
                       map { $_ => $date } qw(start_date end_date),
                      );

   my $res = $self->{ua}->get($self->{url})->result;

   return unless $res->is_success and defined(my $average_bid = $res->json->{response}[0]{average_bid});
   return $amount * $average_bid;
}


