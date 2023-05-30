package Get::Article;

use strict;
use warnings;
use utf8;
use feature qw(fc say);

use Carp       qw(croak);
use List::Util qw(min max);
use Unicode::Normalize;
use Get::Article::Currency;

no warnings 'utf8';

# debug
use Data::Dumper;

my $NUMERIC  = qr/( [-+]? (?:\d+(?: [.]\d* )?|[.]\d+) ) (?: :[eE] ([-+]? (?:\d+)) )? ([^\s]*)/x;
my $MONEY_RE = do {
   local $" = '|';
   my @syms = map { quotemeta } keys %$Get::Article::Currency::SYMBOLS;
   my %inv = (
              ' ' => qr/[,.]/,
              ',' => qr/\./,
              '.' => ',',
             );

   qr~
      \b{wb}
      (?:
         (?<c>(?&x)) \s* (?<u>(?&iso)) |
         (?<u>(?&sym))? \s* (?<c>(?&x)) \s* (?(<u>)|(?<u>(?&sym)))
      )
      \b{wb}
      (?(DEFINE)
         (?<x>
            (?: \d{1,3} (?<sep>[ ,.])\d{3} (?>(?:\g{sep}\d{3})*) | \d+ ) # integer
            (?:(??{ $inv{$+{sep} // ' '} })\d+)? # decimal
         )
         (?<sym>@syms)
         (?<iso>@Get::Article::Currency::CODES)
      )
   ~x
};

sub new {
   bless {
          contents => $_[2],
          article  => {
                      name => $_[1]
                     },
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

sub _jaro {
   my ($s, $t) = @_;

   my ($s_len, $t_len) = (length $s, length $t);

   my (@s_matches, @t_matches);
   my @s = (split //, $s);
   my @t = (split //, $t);

   my $match_distance = (max($s_len, $t_len) / 2) - 1;

   my $n_matches = 0;
   foreach my $i (0 .. $#s) {

      my $start = max(0, $i - $match_distance);
      my $end   = min($i + $match_distance, $#t);

      foreach my $j ($start .. $end) {
         next if $t_matches[$j] or $s[$i] ne $t[$j];
         $s_matches[$i] = $t_matches[$j] = 1;
         $n_matches++;
         last;
      }
   }

   return 0 unless $n_matches;

   my ($k, $transposition) = (0, 0);
   foreach my $i (0 .. $#s) {
      $s_matches[$i] or next;
      ++$k until $t_matches[$k];
      $s[$i] eq $t[$k] or ++$transposition;
      ++$k;
   }

   # return the probability match
   (($n_matches / $s_len) + ($n_matches / $t_len) + (1 - $transposition / (2 * $n_matches))) / 3;
}

sub _jaro_winkler {
   my ($s, $t) = @_;

   my $prefix = 0;
   foreach my $i (0 .. min(3, length($s), length($t))) {
      substr($s, $i, 1) eq substr($t, $i, 1) ? $prefix++ : last;
   }

   my $distance = _jaro($s, $t);
   $distance + $prefix * 0.1 * (1 - $distance);
}

sub _nfkd_normalize {
   my $impurities;
   my $ascii_string = join '', map { $impurities += length() - 1; substr($_, 0, 1) } map { NFKD($_) } split //, $_[0];

   ($ascii_string, $impurities);
}

sub _get_price {
   my $description = shift;

   print "on $description\n";
   my $price;
   push @$price, [$+{c}, $+{u}] while $description =~ /$MONEY_RE/g;
   return $price;
}

sub search_article {
   croak 'need key-value args' if @_ % 2 != 1;
   my $self = shift;
   my $configs = {
                  token_dist => 2,
                  token_perc => 80,
                  jaro       => 0.8,
                  nkfd       => 1,
                  price      => 0,
                 };

   my %args = @_;
   foreach my $key (keys %args) {
      exists $configs->{$key} || croak "unknown config: '$key' => '$args{$key}'";
      $configs->{$key} = $args{$key};
   }

   my $index  = 0;
   my @tokens = grep { length } split /\s+/, fc $self->{article}{name};
   foreach my $paragraph (@{$self->{contents}}) {

      my @description;
      while ($paragraph =~ /\G\s*(.+?\b{wb}(?:[.?!]+|(?=\s*\z))\b{wb})\s*/g) {
         my %passed;
         my $sentence = $1;
         my ($score, $impure, $gaps, $total_jaro) = (0, 0, 0, 0);

         while ($sentence =~ /\G\s*(.+?)\b{wb}\s*/g) {
            my $word = fc $1;

            next if $word =~ /^\p{P}+$/;

            if ($word =~ $NUMERIC) {
               my ($value, $exp, $unit) = ($1, $2 // '', fc $3 // '');

               foreach my $token (@tokens) {
                  if ($token =~ $NUMERIC) {
                     my ($valid_value, $valid_exp, $valid_unit) = ($1, $2 // '', fc $3 // '');

                     next unless $unit eq $valid_unit;
                     next unless $exp eq $valid_exp;
                     if ($value eq $valid_value and !exists $passed{$_}) {
                        $score++;
                        $passed{$_} = 1;
                        last;
                     }
                  }
               }
               next;
            }

            my $impure_value = 0;
            ($word, $impure_value) = _nfkd_normalize($word) if $configs->{nfkd};

            my $got_token = (sort { $b->[1] <=> $a->[1] } map { [$_, _jaro_winkler($_, $word)] } @tokens)[0];
            if ($got_token and $got_token->[1] >= $configs->{jaro} and !exists $passed{$got_token->[0]}) {
               $passed{$got_token->[0]} = 1;
               $total_jaro += $got_token->[1];
               $impure     += $impure_value;
               $score++;
               next;
            }

            if (($score / @tokens) * 100 >= $configs->{token_perc}) {
               push @description,
                 {
                  short  => $sentence,
                  score  => $score,
                  impure => $impure,
                  jaro   => $total_jaro,
                 };
               next;
            }

            if (defined($score) and $gaps > $configs->{token_dist}) {
               %passed = ();
               $score  = $gaps = $impure_value = $total_jaro = 0;
               next;
            }

            $gaps++;
         }
      }

      if (@description) {
         $self->{article}{F}[$index] =
           (sort { $b->{score} <=> $a->{score} || $a->{impure} <=> $b->{impure} || $b->{jaro} <=> $a->{jaro} } @description)
           [0];
         $self->{article}{F}[$index++]{long} = $paragraph;
      }
   }

   if ($configs->{price}) {
      @{$self->{article}{F}} =
        map { $_->{price} = _get_price($_->{long}); $_->{price} ? $_ : () } @{$self->{article}{F}};
   }

   return $self->{article}{F};
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
