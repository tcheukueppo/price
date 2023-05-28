package Get::Article::Exchange;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use POSIX;
use DateTime;
use Mojo::URL;
use Mojo::UserAgent;

use Get::Article::Currency;

use Mojo::Util qw(dumper);

my %codes = map { $_ => 1 } @Get::Article::Currency::CODES;
my $sym   = $Get::Article::Currency::SYMBOLS;

sub new {
   my $url = Mojo::URL
     ->new
     ->scheme('https')
     ->host('fxds-public-exchange-rates-api.oanda.com')
     ->path('/cc-api/currencies');

   bless {
          ua  => $_[1] // Mojo::UserAgent->new,
          url => $url,
         },
     $_[0];
}

sub convert {
   my ($self, $amount, @unit) = @_;

   $_ = (exists $codes{uc $_} ? uc $_ : exists $sym->{$_} ? $sym->{$_}[0] : return) foreach @unit;

   print dumper [@unit], "\n";
   my $date = DateTime->now;
   $self->{url}->query(
                       base       => $unit[0],
                       quote      => $unit[1],
                       data_type  => 'general_currency_pair',
                       end_date   => $date->ymd,
                       start_date => $date->subtract(
                                                     days => 1
                         )->ymd,
                      );

   my $res = $self->{ua}->get("$self->{url}")->result;

   return sprintf '%.2f', $amount * $res->json->{response}[0]{average_bid} if $res->is_success and !exists $res->json->{error};
}

=encoding utf8

=head1 NAME

Get::Article::Exchange - Simple realtime currency converter.

=head1 SYNOPSIS

    use Get::Article::Exchange;

    my $e = Get::Article::Exchange->new;

    # convert from BGP to FCFA
    say $e->convert(1000, BGP => '');

    # works with symbols
    say $e->convert(30, USD => '₹');

=head1 METHODS

=head2 convert

=head1 AUTHOR

Kueppo Tcheukam, C<< <tcheukueppo at tutanota.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-get-article at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Get-Article>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Get::Article::Exchange


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Get-Article>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Get-Article>

=item * Search CPAN

L<https://metacpan.org/release/Get-Article>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Kueppo Tcheukam.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;
