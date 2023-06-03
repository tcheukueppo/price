package Get::Article::Google;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Collection qw(c);

use Carp         qw(croak carp);
use Scalar::Util qw(refaddr);

use Data::Dumper;
use feature qw(say);

my $NO_GOOGLE   = qr{https://(?!(?>\w+\.)*google\.com)};
my $TARGET_LINK = qr{
   (?|
      imgrefurl = ((?> [^&]+ ))
    | (?:q|u)   = ( $NO_GOOGLE (?>[^&]+) )
   )
}x;

my $NESTED_TAGS         = qr/^(?:div|p|span)$/;
my $TEXT_MODIFIERS_TAGS = do {
   '^(?:' . join(
      '|', qw(
        h1 h2 h3 h4 h5 h6 big
        a abbr b bdi bdo cite
        del dfn em i ins kbd acronym
        data label mark meter tt
        output progress q ruby
        s samp slot small strong
        sub sup time u var wbr
        )
     )
     . ')$';
};

sub new {
   bless {
          ua  => $_[1] // Mojo::UserAgent->new(),
          url => Mojo::URL
            ->new
            ->scheme('https')
            ->host('www.google.com')
            ->path('/search')
         },
     $_[0];
}

# google and save results
sub google {
   my ($self, $article, $n) = @_;

   return unless $article;

   $n //= 100;
   $self->{url}->query(q => "price of $article");

   my $tx = $self->{ua}->get("$self->{url}");
   return 0 if !$tx->result->is_success;

   my $c = $tx
     ->result
     ->dom
     ->find('a[href]')
     ->map(attr => 'href')
     ->compact
     ->grep(qr{^\s*[^#]})
     ->map(sub { Mojo::URL->new($_)->query })
     ->compact
     ->map(sub { /$TARGET_LINK/ ? $1 : '' })
     ->compact
     ->uniq
     ->shuffle
     ->head($n);

   $self->{index} = 0;
   $self->{links} = [$c->each];
   return 1;
}

sub next {
   $#{$_[0]->{links}} == $_[0]->{index} ? '' : $_[0]->{links}[++$_[0]->{index}];
}

sub prev {
   $_[0]->{index} == 0 ? '' : $_[0]->{links}[--$_[0]->{index}];
}

sub get_contents {
   my $self = shift;
   my $link = $self->{links} && $self->{links}[++$self->{index}];

   return unless $link;

   #$link = 'https://dir.indiamart.com/impcat/hp-computer-monitor.html';
   my $res = $self->{ua}->get($link)->result;
   return 0 unless $res->is_success;

   my $content;
   $content->{lang} = $res->dom->at('html')->attr('lang') // 'en';
   foreach my $node ($res->dom->find('div, p')->each) {
      my $text = _get_text($node);

      next unless "$text";
      push @{$content->{text}}, ref $text ? $text->to_string : $text;
   }

   $content->{text} = [c(@{$content->{text}})->uniq->each];
   return $content;
}

sub _get_text {
   my $node = shift;

   my $get_text = sub {
      $_->type eq 'text'
        ? $_->content
        : defined($_->tag) ? (
                                $_->tag =~ /$TEXT_MODIFIERS_TAGS/ ? $_->all_text
                              : $_->tag =~ $NESTED_TAGS           ? _get_text($_)
                              :                                     ''
                             )
        : '';
   };

   no warnings 'recursion';
   my $text = $node
     ->child_nodes
     ->map($get_text)
     ->compact
     ->join(' ') =~ s/^\s+//r =~ s/\s+$//r =~ s/\s{2,}/ /gr;    # Beautify!

   return $text;
}
