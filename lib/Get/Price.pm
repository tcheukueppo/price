package Get::Price;

use strict;
use warnings;
use feature qw(state current_sub);

use Carp;
use List::Util qw(min);

# configuration search precision
my %CONFIGS = (
    MAX_INTER_LENGTH     => 1,
    MAX_INNER_WORD_COUNT => 1,
    MAX_OCCURENCE_PERC   => 90,
    TWEAK_CONFIGS        => 1,
    REPSECT_ORDER        => 1,
);

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
    my ( $class, $article, $contents, %configs ) = @_;

    foreach my $key ( keys %configs ) {
        exists $CONFIGS{$key} || Carp::croak "unknown configuration '$key' => $configs{$key}";
        $CONFIGS{$key} = $configs{$key};
    }

    my $self = bless {
        contents => $contents,
        article  => { name => $article, },
    }, $class;

    return $self->generate_article_regex();
}

sub generate_article_regex {
    my $self = shift;
    my $n    = 0;
    my @token_regexs;

    foreach my $token ( grep { length } split /\s+/, $self->{article}{name} ) {
        my $token_regex = '( ';

        $token_regex .= join ' ',
            map { state $x = 0; "(?<c_$n>$_)?" . ( ++$x < length($token) ? "(?<i_$n>.*?)" : '' ) } split '', $token;
        $token_regex .= ') ';

        push @token_regexs, $token_regex;
        $n++;
    }

    $self->{article}{n}      = $n;
    $self->{article}{regexs} = $self->_shuffle_regexs(@token_regexs);
    return $self;
}

sub _shuffle_regexs {
    my ( $self, @token_regexs ) = @_;
    my ( $start, $end, $gap ) = ( '(?:\s*) (?<a> (?<=\A|\s) ', '(?=\s|\Z) ) (?:\s*)', '(?<gap> .*? )' );

    my $perms;
    push @$perms,
        map { qr/$_/xs }
        map { $start . join( $gap, @$_ ) . $end }
        ( $CONFIGS{RESPECT_ORDER} ? [ @token_regexs ] : _permutations(@token_regexs) );

    return $perms;
}

sub search_article {
    my $self = shift;
    my @articles;

READ_CONTENTS: while () {

        my ( @extracted, @re_pos );
        foreach my $index ( 0 .. $self->{article}{regexs}->$#* ) {

            last READ_CONTENTS unless $self->{contents} =~ m/$self->{article}{regexs}[$index]/gso;

            my $n_valid_tokens = 0;
            my ( $total_i, $total_c, $total_gaps );

            foreach my $capture_index ( 1 .. $self->{article}{n} ) {
                my $i      = $-{ 'i_' . $capture_index } // [];
                my $c      = $-{ 'c_' . $capture_index } // [];
                my $nwords = defined $-{gap}[ $capture_index - 1 ]
                    ? () = $-{gap}[ $capture_index - 1 ] =~ m/(?<=\s{0,1})(\S+)(?=\s{0,1})/gx
                    : 0;

                $total_i    += @$i;
                $total_c    += @$c;
                $total_gaps += $nwords;

                no strict 'refs';
                if (   ( ( @$c / length $$capture_index ) * 100 < $CONFIGS{MAX_OCCURENCE_PERC} )
                    || ( grep { defined && length > $CONFIGS{MAX_INTER_LENGTH} } @$i ) ) {
                    next;
                }

                push @re_pos, $-[ $capture_index ] if $nwords <= $CONFIGS{MAX_WORD_COUNT_BETWEEN};
                $n_valid_tokens++;
            }

            next if $n_valid_tokens == 0;

            if ( ( $n_valid_tokens / $self->{article}{n} ) * 100 >= $CONFIGS{VALID_TOKEN_PERC} ) {
                push @extracted, {
                    extracted       => $+{a},
                    n_invalid_chars => $total_i,
                    n_valid_chars   => $total_c,
                    n_gaps          => $total_gaps,
                    likely          => $index,
                };
            }
        }

        if (@re_pos) {
            my $min_pos = min @re_pos;
            pos $_ = $min_pos foreach $self->{article}{regexs};
        }

        if (@extracted) {
            push @articles, sort {
                       $b->{n_valid_chars}   <=> $a->{n_valid_chars}
                    || $b->{n_invalid_chars} <=> $a->{n_invalid_chars}
                    || $b->{n_gaps}          <=> $a->{n_gaps}
                    || $b->{likely}          <=> $a->{likely}
            } @extracted;
        }
    }

    return @articles;
}

sub _permutations {
    my @token_regexs = @_;
    state( @perms, @stack );

    if (@token_regexs) {
        foreach my $index ( 0 .. $#token_regexs ) {
            push @stack, delete $token_regexs[ $index ];
            __SUB__->_permutations(@token_regexs);
            pop @stack;
        }
    }
    else {
        my $shuffled_article;
        push @perms, $shuffled_article;
    }

    return @perms;
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

1;    # End of Get::Price
