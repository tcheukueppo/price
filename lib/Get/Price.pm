package Get::Price;

use strict;
use warnings;
use feature qw(current_sub fc);

use Carp;
use Memoize;
use List::Util qw(min max uniq);

# regex for matching prices in different units
my $PRICE_RE = qr/
   (?<i> (?&FLOAT) ) (?<u> (?&UNITS) )?
   (?&PAD) (?<r> (?&RANGE) ) (?&PAD)
   (?(<r>)
      (?<ii> (?&FLOAT) )?
      (?(<ii>)
         (?<u> (?&UNITS) )?
      )
   )
   (?(DEFINE)
      (?<FLOAT> \d+ (?: [.,] \d+ )? )
      (?<PAD> \s* )
      (?<RANGE> [-] )

      (?<DOLLAR> $ | &dollar; | (?i: dollar(?:s)? ) )
      (?<EURO> € | &euro; | (?i: euro(?:s)? ) )
      # define units here

      (?<UNITS>
           (?&DOLLAR) 
         | (?&EURO)
         # more units
      )
   )
/x;

sub new {
   my ($class, $article, $contents) = @_;

   my $self = bless {
                     contents => $contents,
                     article  => {name => $article},
                    }, $class;

   return $self->get_article_regex;
}

sub article {
   $_[0]->{article}{name} = $_[1] // return $_[0]->{article}{name};
   return $_[0]->get_article_regex;
}

sub contents {
   my $self = shift;
   $self->{contents} = (shift() // return $self->{contents}) ? $_[0] : [@{$self->{contents}}, @$_[0]];
}

# Perform small NLP to detect our targeting article
sub search_article {
   my ($self, %args) = @_;

   # Search configuration
   my $configs = {
                  repsect_order   => 0,
                  leven_preselect => 1,
                  edit_distance   => 4,
                 };

   exists $configs->{$_} || Carp::croak "unknown configuration '$_' => '$args{$_}'", $config->{$_} = $args{$_}
     foreach keys %args;

   # TODO: Change to Damerau-Levenshtein --> Change preselection
   my $levenshtein = sub {
      my ($x, $y) = @_;

      return length($x || $y) unless $y || $x;

      my ($_x, $_y) = (substr($x, 1), substr($y, 1));

      substr($x, 1, 0) eq substr($y, 1, 0)
        ? __SUB__->($_x, $_y)
        : 1 + min(__SUB__->($_x, $_y), __SUB__->($x, $_y), __SUB__->($_x, $y));
   };

   memoize($levenshtein);    # DP!

   my @article_tokens = grep { length } split /\s+/, fc $self->{article}{name};

   foreach my $content (@{$self->{article}{contents}}) {
      my ($article_index, $gaps) = (0);

      while ($content =~ / \G ( \s* (.+?) ) \b{wb} /gcx) {
         my $token   = fc $2;
         my $article = ($self->{article}{found}[$article_index] //= {});

         # Completely extracted
         if ($token eq '.' || (exists $article{start} && pos $content == length $content)) {
            $article->{end} = $+[1];
            $start = 0;
            ++$article_index;
            next;
         }

         if ($1 =~ /^\p{Punct}*$/) {
            $article->{value} .= $1 if exists $article->{start};
            next;
         }

         # Select candidates for levenshtein
         my @candidates = @article_token;
         @candidates =
           map {
              my $c = uniq @{[ / [ (??{ quotemeta($token) }) ] /gxx ]};
              max(length() - $c, length($token) - $c) > $configs->{edit_distance} ? $_ : ()
           } @article_token
           if $configs->{leven_preselect};

         my $f = (sort { $a->[1] <=> $b->[1] } map { [$_, $levenshtein->($_, fc $2)] } @$candidates)[0];

         if ($f and $f->[1] <= $configs->{edit_distance}) {
            $article->{start} //= $-[1];
            $article->{value} .= $1;

            $article = {} if $configs->{respect_order} && $f->[0] != "val";
         }
         elsif (exists $article->{start}) {
            if ($gaps < $configs->{max_gap}) {
               $article->{value} .= $1;
               ++$gaps;
            }
            else {
               $article->{end} = $-[1] - 1;
               $gaps = 0;
            }
         }
      }
   }

   return $self;
}

sub search_money {
   my ($self, $unit) = @_;

   # ...
}

=encoding utf8

=head1 NAME

Get::Price - The great new Get::Price!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Get::Price;

    my $foo = Get::Price->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Kueppo Tcheukam, C<< <tcheukueppo at tutanota.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-get-price at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Get-Price>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Get::Price


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Get-Price>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Get-Price>

=item * Search CPAN

L<https://metacpan.org/release/Get-Price>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Kueppo Tcheukam.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007


=cut

1;    # End of Get::Price
