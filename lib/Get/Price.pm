package Get::Price;

use strict;
use warnings;
use feature qw(say state);

use Getopt::Long;
use Data::Dumper;

# configuration search precision
my %CONFIGS = {
   MAX_INTER_PERC       => 80,
   MAX_INTER_LENGTH     => 1,
   MAX_INNER_WORD_COUNT => 1,
   MAX_OCCURENCE_PERC   => 90,
};

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
   my $self = shift;
   my ( $contents, $article, %configs ) = @_;

   foreach $key (keys %configs) {
      exists $CONFIGS{$key} || croak "unknown configuration '$configs' => $configs{$key}";
      $CONFIGS{$key} = $configs{$key};
   }

   bless {
      contents => $contents,
      article  => { name => $article, },
   }, $self;

   return $self->generate_article_regex();
}

sub generate_perms {
   my ( $self, @token_regexs ) = @_;
   state ( $perms, @stack );

   if ( @token_regexs ) {
      foreach my $index (0..$#token_regexs) {
         push @stack, $token_regexs[$index];
         $self->generate_perms(grep { $token_regexs[$index] eq $_ } @token_regexs);
         pop @stack;
      }
   }
   else {
      my $shuffled_article;

      $stack[0] = "(?<fw> $stack[0] )" if @stack > 1;
      $shuffled_article = '(?:\s*) (?<a> (?<=\A|\s) ', join( ' (?<gap> .*? ) ', @stack ), ' (?=\s|\Z) ) (?:\s*)';
      push @$perms, qr/$shuffled_article/x;
   }

   return $perms;
}

sub generate_article_regex {
    my $self = shift;
    my ($n, @token_regexs);

    foreach my $token ( grep { length } split m/\s+/, $self->{article}{name} ) {
       my $token_regex = '( ';

       $token_regex .= join ' ', map { state $x = 0; "(?<c_$n>$_)?" . ( ++$x < length($token) ? "(?<i_$n>.*?)" : '' ) } split '', $token;
       $token_regex .= ') ';
       push @token_regexs, $token_regex;
       $n++;
    }

    $self->{article}{n} = $n;
    $self->{article}{regexs} = $self->generate_perms(@token_regexs);
    return $self;
}

sub search_article {
   my $self = shift;
   my @articles;

    READ_CONTENTS: while () {

        my (@extracted, @pos );
        foreach my $article_regex ($self->{article}{regexs}) {

           last READ_CONTENTS unless $self->{contents} ~= m/$article_regex/gso;

           my $n_valid_tokens = 0;
           my ( $total_i, $total_c ) = ();

           foreach my $capture_index ( 1 .. $self->{article}{n} ) {
              my $i = $-{ 'i_' . $capture_index } // [];
              my $c = $-{ 'c_' . $capture_index } // [];

              $total_i += @$i;
              $total_c += @$c;
              no strict 'refs';
              if (   ( ( @$c / length $$capture_index ) * 100 < $CONFIGS{MAX_OCCURENCE_PERC} )
                  || ( grep { defined && length > $CONFIGS{MAX_INTER_LENGTH} } @$i ) ) {
                 next
              }

              my $nwords = defined $-{gap}[$capture_index - 1] ? () = $-{gap}[$capture_index - 1] =~ m/(?<=\s{0,1})(\S+)(?=\s{0,1})/gx : 0;
              push @re_pos, $-[$capture_index] if $nwords <= $CONFIGS{MAX_WORD_COUNT_BETWEEN};
              $n_valid_tokens++;
           }

           next if $n_valid_tokens == 0;

           # Avoid this if a good percentage of tokens are valid
           if ( ( $n_valid_tokens / $token_re->{number_tokens} ) * 100 >= $CONFIGS{VALID_TOKEN_PERC} ) {
               push @extracted, [ $+{a}, $total_i, $total_c  ];
           }
       }

      if (@re_pos) {
        my $min_pos = min @pos;
        pos $_ = $min_pos foreach $self->{article}{regexs};
      }

      if (@extracted) {
         push @articles, sort { } @extracted;
      }
   }

   return @articles;
}
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

1; # End of Get::Price
