package Get::Price;

use strict;
use warnings;
use feature qw(current_sub fc say);

use Carp;
use Memoize;
use List::Util qw(min max reduce sum);

use Data::Dumper;

# Regex for matching prices in different units
my $PRICE_RE = qr/
   (?<i> (?&FLOAT) ) (?<u> (?&UNIT) )?
   (?&PAD) (?<r> (?&RANGE) ) (?&PAD)
   (?(<r>)
      (?<ii> (?&FLOAT) )?
      (?(<ii>)
         (?<u> (?&UNIT) )?
      )
   )
   (?(DEFINE)
      (?<FLOAT> \d+ (?: [.,] \d+ )? )
      (?<PAD> \s* )
      (?<RANGE> [-] )

      (?<DOLLAR> $ | &dollar; | (?i: dollar(?:s)? ) )
      (?<EURO> € | &euro; | (?i: euro(?:s)? ) )
      # define units here

      (?<UNIT>
           (?&DOLLAR) 
         | (?&EURO)
         # more units
      )
   )
/x;

sub new {
   bless {
          contents => $_[2],
          article  => {name => $_[1]},
         },
     $_[0];
}

sub article {
   $_[0]->{article}{name} = $_[1] // return $_[0]->{article}{name};
   return $_[0];
}

sub contents {
   $_[1] ? push @{$_[0]->{contents}}, @{$_[1]} : return @{$_[0]->{contents}};
   return $_[0];
}

sub rm_contents {
   delete $_[0]->{contents};
}

# Compute jaro similarity btw two strings
sub _jaro {
   my ($s, $t) = @_;

   my ($s_len, $t_len) = (length $s, length $t);

   my (@s_matches, @t_matches);
   my @s = (split //, $s);
   my @t = (split //, $t);

   my $match_distance = (max($s_len, $t_len) / 2) - 1;

   # Find number of matches based on $match_distance condition
   my $n_matches = 0;
   foreach my $i (0 .. $#s) {

      my $start = max(0, $i - $match_distance);
      my $end   = min($i + $match_distance, $#t)

      foreach my $j ($start .. $end) {
         next if $t_matches[$j] or $s[$i] ne $t[$i];
         $s_matches[$i] = $t_matches[$j] = 0;
         $matches++;
         last;
      }
   }

   return 0 unless $n_matches;

   # Find number of transpositions
   my ($k, $transposition) = (0, 0);
   foreach my $i (0 .. $#s) {
      $s_matches[$i] or next;
      ++$k until $t_matches[$k];
      $s[$i] eq $t[$k] or ++$trans;
      ++$k;
   }

   # return the probability match
   (($n_matches / $s_len) + ($n_matches / $t_len) + (1 - $trans / (2 * $matches))) / 3
}

# Perform small NLP to detect our targeting article
sub search_article {
   Carp::croak '$self->search_article only accept key-value arguments' if @_ % 2 != 1;

   my ($self, %args) = @_;

   # Search configuration
   my $configs = {
                  leven_preselect => 1,
                  precision       => 2,
                  edit_distance   => 3,
                 };

   exists $configs->{$_} || Carp::croak("unknown configuration '$_' => '$args{$_}'"), $configs->{$_} = $args{$_}
     foreach keys %args;

   # TODO: change to Damerau-Levenshtein and thus modify pre-selection code
   my $levenshtein = sub {
      my ($x, $y) = @_;

      return length($x || $y) unless ($y ? $x : $y);

      my ($_x, $_y) = (substr($x, 1), substr($y, 1));

      substr($x, 1, 0) eq substr($y, 1, 0)
        ? __SUB__->($_x, $_y)
        : 1 + min(__SUB__->($_x, $_y), __SUB__->($x, $_y), __SUB__->($_x, $y));
   };

   memoize($levenshtein);    # DP!

   $self->{article}{F} //= [];

   my @tokens = grep { length } split /\s+/, fc $self->{article}{name};

   foreach my $paragraph (@{$self->{contents}}) {
      my $index = 0;

      while ($paragraph =~ /\G \s* ( .+? \b{wb}(?: [.] | (?= \s+ \Z ) )\b{wb} ) \s*/gsx) {

         my $sentence = $1;
         my $description;
         my ($score, $gaps) = (0, 0);

         while ($sentence =~ /\G \s* (.+?) \b{wb} \s*/gcsx) {
            my $token = fc $1;

            # Completely extracted
            if ($token eq '.' || pos($sentence) == length $sentence) {
               $description = [$score, $sentence]
                 if ($score == @tokens) || $score > 1 and !defined($description) || $description->[0] < $score;
               last;
            }

            next if $token =~ /^\p{Punct}+$/;

            # Select candidates for levenshtein
            my $candidates;

            if ($configs->{leven_preselect}) {
               my $token = $token;

               foreach my $a_token (@tokens) {
                  my $c = sum map { $token =~ s/\Q$_\E// } split //, $a_token;
                  push @$candidates, $a_token if max(length($a_token) - $c, length($token) - $c) < $configs->{edit_distance};
               }
            }
            else {
               $candidates = \@tokens;
            }

            my $f = (sort { $a->[1] <=> $b->[1] } map { [$_, $levenshtein->($_, $token)] } @$candidates)[0];
            if ($f and $f->[1] <= $configs->{edit_distance}) {
               #say "success with: @$f, $token";
               $score++;
               next;
            }

            # Distance btw tokens measures how much involved the article name
            # is in the sentence.
            if ($gaps > $configs->{precision} and defined($score) and $score == 1) {
               $score = 0;
               $gaps  = 0;
            }
            else {
               $gaps++;
            }
         }

         if ($description) {
            $self->{article}{F}[$index]{short} = $description;
            $self->{article}{F}[$index++]{long} = $paragraph;
         }
      }
   }

   if ($configs->{price}) {
      $_->{price} = $self->get_price($_) foreach @{$self->{article}{F}};
   }

   return @{$self->{article}{F}};
}

sub get_price {
   my ($self, $article) = @_;

}

sub nfkd_normalize {
   my ($self, $unicode_string) = @_;

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
