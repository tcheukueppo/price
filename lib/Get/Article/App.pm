package Article::App;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use Getopt::Long;
use Get::Article;
use Get::Article::Exchange;
use Get::Article::Google;

sub app {
   # start app here
}

sub main {
   carp 'Err: please sent key-value Mojo::UserAgent options' if @_ % 2 == 0;
   my ($class, %args) = @_;

   my $self = {ua => Mojo::UserAgent->new()};
   foreach my $method (keys %args) {
      eval { $self->{ua}->$method($args{$method}) };
      carp "invalid 'Mojo::UserAgent' option: $method" if $@;
   }

   $self->{url} = Mojo::URL->new('https://www.google.com/search');
   bless $self, $class;
}
