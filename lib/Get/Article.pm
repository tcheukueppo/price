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

our $VERSION = '0.01';
our $REGMARK = '';

my $NUMERIC  = qr/( [-+]? (?:\d+(?: [.]\d* )?|[.]\d+) ) (?: [eE] ([-+]? (?:\d+)) )? ([^\s]*)/x;
my $MONEY_RE = do {
   local $" = '|';

   # why not quotemeta? ;-)
   my @symbols = map { s/\./\\./r =~ s/\$/\\\$/r } keys %Get::Article::Currency::SYMBOLS;
   my @codes   = keys %Get::Article::Currency::CODES;
   my %inv = (
                ',' => qr/[.]/,
                '.' => ',',
                ' ' => qr/[,.]/,
             );
   qr~
      \b{wb}
      (?:
         (?<c>(?&x)) \s{0,1} (?<u>(?&iso)) |
         (?<u>(?&sym)(*MARK:front))? \s{0,1} (?<c>(?&x)) \s{0,1} (?(<u>)|(?<u>(?&sym)))
      )
      \b{wb}
      (?(DEFINE)
         (?<x>
            (?: \d{1,3} (?<sep>[ ,.])\d{3} (?>(?:\g{sep}\d{3})*) | \d+ ) # integer
            (?:(??{ $inv{$+{sep} // ' '} })\d+)? # decimal
         )
         (?<iso>@codes)
         (?<sym>@symbols)
      )
   ~xu
};

sub new {
   bless {
          content => $_[2],
          article => {
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
   $_[0]->{content} = $_[1] // return @{$_[0]->{content}};
   return $_[0];
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

   # return the match probability
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
   return join '', map { substr($_, 0, 1) } map { NFKD($_) } split //, $_[0];
}

sub _get_price {
   my $description = shift;

   my $price;
   while ($description =~ /\G.*?$MONEY_RE/gu) {

      next if $+{c} =~ /^[0,.]+$/;
      $price = [$+{c}, $+{u}, $REGMARK eq 'front' ? 1 : 0];
      last;
   }

   return $price;
}

sub search_article {
   croak 'need key-value args' if @_ % 2 != 1;
   my $self = shift;
   my $configs = {
                  token_dist => 2,
                  jaro       => 0.8,
                  price      => 0,
                  token_perc => 80,
                  nfkd       => 1,
                 };

   my %args = @_;
   foreach my $key (keys %args) {
      exists $configs->{$key} || croak "unknown config: '$key' => '$args{$key}'";
      $configs->{$key} = $args{$key};
   }

   my $found;
   my $index  = 0;
   my @tokens = grep { length } split /\s+/, fc $self->{article}{name};

   @tokens = map { _nfkd_normalize($_) } @tokens if $configs->{nfkd};
   foreach my $content (@{$self->{content}}) {
      #say Dumper $content;
      my (@description, $price);

      if ($configs->{price}) {
         my @prices = grep { defined } map { _get_price($_) } @{$content->{numeric}} if @{$content->{numeric}};
         $price = (sort { $b->[0] <=> $a->[0] } @prices)[0] if @prices;
         #say $price if defined $price;
         next unless defined($price //= _get_price($content->{extracted}));
      }

      while ($content->{extracted} =~ /\G\s*(.+?\b{wb}(?:[.?!]+|(?=\s*\z))\b{wb})\s*/g) {
         my $sentence = $1;
         my $gaps     = 0;
         my (%passed, %param);

         $param{$_} = 0 foreach qw(score jaro);
         while ($sentence =~ /\G\s*(.+?)\b{wb}\s*/g) {

            if ($param{score} > 1 and $gaps > $configs->{token_dist}) {
               %passed    = ();
               $param{$_} = 0 foreach qw(score jaro);
               $gaps      = 0;
            }

            my $word  = fc $1;
            my $score = $param{score};

            next if $word =~ /^\p{P}+$/;

            $word = _nfkd_normalize($word) if $configs->{nfkd};
            if ($word =~ $NUMERIC) {
               my ($value, $exp, $unit) = ($1, $2 // '', fc $3 // '');

               foreach my $token (@tokens) {
                  next unless $token =~ $NUMERIC;
                  my ($valid_value, $valid_exp, $valid_unit) = ($1, $2 // '', fc $3 // '');

                  if (    $value eq $valid_value
                       && $exp eq $valid_exp
                       && $unit eq $valid_unit
                       && !exists $passed{$token}) {
                     $passed{$token} = 1;
                     ++$param{score} and last;
                  }
               }
            }
            else {
               my $matched = (sort { $b->[1] <=> $a->[1] } map { [$_, _jaro_winkler($_, $word)] } @tokens)[0];

               if ($matched && $matched->[1] >= $configs->{jaro} && !exists $passed{$matched->[0]}) {
                  $param{score}++;
                  $param{jaro} += $matched->[1];
                  $passed{$matched->[0]} = 1;
               }
            }

            if ($score < $param{score} && ($param{score} / @tokens) * 100 >= $configs->{token_perc}) {
               push @description,
                 {%param, short => $sentence,};
               last;
            }
         }
      }

      if (@description) {
         my $valid_des = (sort { $b->{score} <=> $a->{score} || $b->{jaro} <=> $a->{jaro} } @description)[0];

         $found->[$index] = {%{$valid_des}{qw(jaro score)}};
         $found->[$index]{price} = _get_price($valid_des->{short}) // $price if $configs->{price};
         $found->[$index++]{description} = $content->{extracted};
      }
   }

   return $found;
}

=encoding utf8

=head1 NAME

Get::Article - Search article descriptions and prices

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Search descriptions and prices of an article in contents.

    use Get::Article;

    my $a = Get::Article->new('banana', $contents);

    # search article 'banana' in contents found in $contents
    my $found = $a->search_article()

=head1 METHODS

=head2 contents

Set content on which the search is going to be performed.

   $a->contents(["some text ...", "..."]);

=head2 article

Set the name of the article to be searched in contents.

   $a->article("Hp PrôbOôk 6550b");

=head2 search_article

Search article in the contents. it returns an array reference containing
the result of the search.

   $a->search_article(%options);

=over

=item options

=item return value

=back

=head1 SUBROUTINES

=head2 _nfkd_normalize

=head2 _jaro

=head2 _jaro_winkler

=head1 AUTHOR

Kueppo Tcheukam, C<< <tcheukueppo at tutanota.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-get-article at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Get-Article>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Get::Article


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Get-Article>

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
