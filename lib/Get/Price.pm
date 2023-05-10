package Get::Price;

use strict;
use warnings;
use feature qw(say state);

use Getopt::Long;
use Data::Dumper;

# Configuration search precision
my %CONFIGS = {
   MAX_INTER            => 2,
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
      $shuffled_article = '(?:\s*) ( (?<=\A|\s) ', join( ' ', @stack ), ' (?=\s|\Z) ) (?:\s*)';
      push @$perms, qr/$shuffled_article/x;
   }

   return $perms;
}

sub generate_article_regex {
    my $self = shift;
    my ($n, @token_regexs);

    foreach my $token ( grep { length } split m/\s+/, $self->{article}{name} ) {
       my $token_regex;

       $token_regex = join ' ', map { state $x = 0; "(?<c_$n>$_)?" . ( ++$x < length $token ? "(?<i_$n>.*?)" : '' ) } split '', $token;
       push @token_regexs, $token_regex;
       $n++;
    }

    $self->{article}{ntoken} = $n;
    $self->{article}{regex} = $self->generate_perms(@token_regexs);
    return $self;
}

sub search_article {
   my $self = shift;
    my @target_article;

    while ( $tags_content =~ m/$token_re->{regex}/gso ) {
        my $nwords = 0;

        foreach my $inner_words ( grep { defined } $-{words}->@* ) {
            $nwords = () = $inner_words =~ m/ (?<=\s{0,1}) (\S+) (?=\s{0,1}) /gx;

            if ( $nwords > $CONFIGS{MAX_WORD_COUNT_BETWEEN} ) {
               if ( pos( $token_re->{regex}) != length $tags_content ) {
                  pos $token_re->{regex} = $+[1] + 1;
               }
               next 2;
            }
        }

        my $valid_tokens = 0;
        my ( $total_i, $total_c ) = ();

        foreach my $cap_index ( 1 .. $token_re->{number_tokens} ) {
           my $i = $-{ 'i_' . $cap_index } // [];
           my $c = $-{ 'c_' . $cap_index } // [];

           $total_i += @$i;
           $total_c += @$c;
           if (   ( ( @$c / length $article ) * 100 < $CONFIGS{MAX_OCCURENCE_PERC} )
               || ( grep { defined } @$i > $MAX_INTER )
               || ( grep { defined && length > $CONFIGS{MAX_INTER_LENGTH} } @$i ) ) {
              next
           }
           $valid_tokens++;
        }

        # Avoid this if a good percentage of tokens are valid
        if ( ( $valid_tokens / $token_re->{number_tokens} ) * 100 < $CONFIGS{VALID_TOKEN_PERC} ) {
            if ( pos( $token_re->{regex}) != length $tags_content ) {
               pos $token_re->{regex} = $+[1] + 1;
            }
        }
        else {
            push @target_article, [ $1, $nwords, $total_i, $total_c  ];
        }
    }

    return (
       sort {
          $b->[ 3 ] <=> $a->[ 3 ]
                    ||
          $a->[ 2 ] <=> $b->[ 2 ]
                    ||
          $a->[ 1 ] <=> $b->[ 1 ]
       } @target_article
    ) [ @target_article ][ 0 ];
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
