package Get::Article::Google;

use strict;
use warnings;
use utf8;
use feature qw(say state);

no warnings 'utf8';

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Collection qw(c);

use Carp         qw(croak carp);
use Scalar::Util qw(refaddr);

use Data::Dumper;

my $ANY_QUANTITY = qr/^(\S+)?\s*\d(?>(?:[\d.,] ?)+)?\d?\s*(?(1)|\S+)$/;
my $NO_GOOGLE    = qr~https://(?!(?>\w+\.)*google\.com)~;
my $TARGET_LINK  = qr~
   (?|
      imgrefurl = ((?> [^&]+ ))
    | (?:q|u)   = ( $NO_GOOGLE (?>[^&]+) )
   )
~x;

my $NESTED_TAGS = qr/^(?:div|p|span)$/;

# Tags which modify strings characteristics
my $TEXT_MODIFIERS_TAGS = do {
   local $" = '|';

   #h1 h2 h3 h4 h5 h6 big a
   my @modifiers = qw(
      abbr b bdi bdo big cite
      del dfn em i ins kbd acronym
      data label mark meter tt
      output progress q ruby
      s samp slot small strong
      sub sup time u var wbr
   );

   qr/^(?:@modifiers)$/;
};

my ($index, $max_length) = (-1, 50);

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

   $index = -1;
   $self->{links} = [$c->each];
   return 1;
}

sub next {
   $#{$_[0]->{links}} == $index ? '' : $_[0]->{links}[++$index];
}

sub prev {
   $index == 0 ? '' : $_[0]->{links}[--$index];
}

sub _beautify {
   my $text = "$_[0]" =~ s/^\s+//r =~ s/\s+$//r =~ s/\s{2,}/ /gr;
   1 == length $text ? '' : $text;
}

sub _get_text {
   state ($text, $params);

   no warnings 'recursion';
   $text = '', $params = [] if defined $_[1];    # top level
   foreach my $node ($_[0]->child_nodes->each) {
      if ($node->type eq 'text') {
         next unless length(my $node_text = _beautify($node->content));

         if    ($node_text =~ /$ANY_QUANTITY/p)                            { push @$params, ${^MATCH} }
         elsif ($node_text =~ /\.$/ and length($node_text) >= $max_length) { $text .= ($text ? "\n" : '') . $node_text }
      }
      elsif (defined($node->tag)) {
         if    ($node->tag =~ $NESTED_TAGS) { _get_text($node) }
         elsif ($node->tag =~ $TEXT_MODIFIERS_TAGS) {
            next unless length(my $node_text = _beautify($node->text));
            $text .= ($text ? ' ' : '') . $node_text;
         }
      }
   }

   if (defined($_[1]) && length($text) >= $max_length) {
      local $" = ' ';
      return "@$params\n$text";
   }
}

sub get_contents {
   my $self = shift;
   my $link = $self->{links} && $self->{links}[$index == -1 ? ++$index : $index];

   return unless $link;

   $link = 'https://dir.indiamart.com/impcat/hp-computer-monitor.html';
   my $res = $self->{ua}->get($link)->result;
   return 0 unless $res->is_success;

   my $content;
   $content->{lang} = $res->dom->at('html')->attr('lang') // 'en';
   foreach my $node ($res->dom->at('body')->find('div, p')->each) {
      my $text = _get_text($node, 1);

      next unless "$text";
      push @{$content->{text}}, ref $text ? $text->to_string : $text;
   }

   $content->{text} = [c(@{$content->{text}})->uniq->each];
   return $content;
}

1;
