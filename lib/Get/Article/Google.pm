package Get::Article::Google;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use Mojo::UserAgent;
use Mojo::URL;

use Carp         qw(croak carp);
use Scalar::Util qw(refaddr);

use Data::Dumper;
use feature qw(say);

my $NO_GOOGLE   = qr{https://(?!(?>\w+\.)*google\.com)};
my $TARGET_LINK = qr{
   (?|
      imgrefurl   = (?> [^&]+ )
    | (?:q|url|u) = ( $NO_GOOGLE (?>[^&]+) )
   )
}x;

my $NESTED_TAGS         = qr/^(?:div|span)$/;
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
   carp 'Err: please sent key-value Mojo::UserAgent options' if @_ % 2 == 0;
   my ($class, %args) = @_;

   my $self = {ua => Mojo::UserAgent->new()};
   foreach my $method (keys %args) {
      eval { $self->{ua}->$method($args{$method}) };
      carp "invalid 'Mojo::UserAgent' option: $method" if $@;
   }

   $self->{url} = Mojo::URL->new('https://www.google.com/search');
   bless $self, $class;
}

# google and save results
sub google {
   my ($self, $article, $n) = @_;

   return unless $article;

   $n //= 4;
   $self->{url}->query(q => $article);

   my $tx = $self->{ua}->get("$self->{url}");
   return -1 if !$tx->result->is_success;

   my $c = $tx
     ->result
     ->dom
     ->find('a[href]')
     ->map(attr => 'href')
     ->compact
     ->grep(qr{[^/#]})
     ->map(sub { Mojo::URL->new($_)->query })
     ->compact
     ->map(sub { /$TARGET_LINK/ ? $1 : '' })
     ->compact
     ->uniq
     ->head($n);

   $self->{index} = 0;
   $self->{links} = [$c->shuffle->each];
   return 1;
}

sub next {
   $_[0]->{index} == $#{$_[0]->{links}} ? -1 : $_[0]->{index}++;
}

sub prev {
   $_[0]->{index} == 0 ? -1 : $_[0]->{index}--;
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
     ->join(' ') =~ s/^\s+//r =~ s/\s+$//r =~ s/\s{2,}/ /gr; # Beautify!

   return $text;
}

sub get_content {
   my $self = shift;
   my $link = $self->{links} && $self->{links}[++$self->{index}];

   return unless $link;

   $link = 'https://dir.indiamart.com/impcat/hp-computer-monitor.html';
   my $tx = $self->{ua}->get($link);
   return -1 unless $tx->result->is_success;

   my $content;
   my $index = 0;
   foreach my $node ($tx->result->dom->find('p, div')->each) {
      my $text = _get_text($node);

      next unless $text;

      $content->[$index]{id}   = refaddr($node);
      $content->[$index]{text} = $text;
      $content->[$index]{name} = $node->tag;

      $index++;
   }

   return $content;
}
