package Get::Price;

use strict;
use warnings;
use feature qw(say);

use Getopt::Long;
use Data::Dumper;

my $MAX_INTER            = 2;
my $MAX_INTER_LENGTH     = 1;
my $MAX_INNER_WORD_COUNT = 1;
my $MAX_OCCURENCE_PERC   = 90;

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
   my $class = shift;
   my $text  = shift;

   bless $text, $class;
}

sub generate_article_regex {
    my $article = shift;
    my @token_re;
    my ( $capture_index, $n_tokens ) = ( -1, 0 );

    foreach my $token ( grep { length } split m/\s+/, $article ) {
        my $token_re = ' (?<=\s) ';

        if ( length $token > 1 ) {
            $token_re .= join ' ',
                map "(?<c_$n_tokens>$_)? (?<i_$n_tokens>.*?)", ( split '', $token )[ 0 .. length( $token ) - 2 ];
            $token_re .= " (?<c_$n_tokens>" . chop( $token ) . ')?';
        }
        else {
            $token_re .= "(?<c_$n_tokens>$token)";
        }

        push @token_re, $token_re . ' (?=\s) ';
        $n_tokens++;
    }

    my $article_regex = '(?:\s+) (' . join( ' (?<words>.*?) ', @token_re ) . ') (?:\s+)';
    return {
        number_tokens => $n_tokens,
        regex => qr/$article_regex/x,
     };
}

sub apply_edit_distance {
    my ( $token_re, $article, $tags_content, $config ) = @_;
    my @target_article;

    while ( $tags_content =~ m/$token_re->{regex}/gso ) {
        my $nwords = 0;

        foreach my $inner_words ( grep { defined } $-{words}->@* ) {
            $nwords = () = $inner_words =~ m/ (?<=\s{0,1}) (\S+) (?=\s{0,1}) /gx;

            if ( $nwords > $config->{MAX_WORD_COUNT_BETWEEN} ) {
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
           if (   ( ( @$c / length $article ) * 100 < $config->{MAX_OCCURENCE_PERC} )
               || ( grep { defined } @$i > $MAX_INTER )
               || ( grep { defined && length > $config->{MAX_INTER_LENGTH} } @$i ) ) {
              next
           }
           $valid_tokens++;
        }

        # Avoid this if a good percentage of tokens are valid
        if ( ( $valid_tokens / $token_re->{number_tokens} ) * 100 < $config->{VALID_TOKEN_PERC} ) {
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
