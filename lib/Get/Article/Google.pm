package Get::Article::Google;

use Mojo::UserAgent;
use Mojo::URL;

use Carp qw(croak carp);
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

my $TEXT_MODIFIERS = do {
   '^' . join(
      '|', qw(
         a abbr area b bdi bdo cite data 
         datalist del dfn em i ins kbd keygen
         label map mark meter object output
         progress q ruby s samp slot small span
         strong sub sup time u var wbr acronym
         applet basefont big tt
        )
     )
     . '$';
};

sub new {
   carp 'send key-value mojo ua options' if @_ % 2 == 0;
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
     ->grep(qr{[^/]})
     ->map(sub { Mojo::URL->new($_)->query })
     ->compact
     ->map(sub { /$TARGET_LINK/ ? $1 : '' })
     ->compact
     ->head($n);

   $self->{index} = 0;
   $self->{links} = [$c->each];
   return 1;
}

sub next_link {
   $_[0]->{index} == $#{$_[0]->{links}} ? -1 : $_[0]->{index}++;
}

sub prev_link {
   $_[0]->{index} == 0 ? -1 : $_[0]->{index}--;
}

sub get_content {
   my $self = shift;
   my $link = $self->{links} && $self->{links}[++$self->{index}];

   return unless $link;

   my $tx = $self->{ua}->get($link);
   return -1 unless $tx->result->is_success;

   my $content;
   my $index = 0;
   foreach my $p ($tx->result->dom->find('p')) {

      $content->[$index]{c}{id}   = refaddr($p);
      $content->[$index]{c}{text} = $p
         ->child_nodes
         ->grep(sub { $_->type eq 'text' or $_->tag =~ $TEXT_MODIFIERS })
         ->map('content')
         ->join('') =~ s/^\s+//r =~ s/\s+$//r =~ s/\s{2,}|\R/ /r;

      $content->[$index++]{c_ids} = [$p
         ->child_nodes
         ->grep(sub { $_->tag eq 'p' })
         ->map(sub { refaddr($_) })
         ->each
      ];
   }

   return $content;
}
