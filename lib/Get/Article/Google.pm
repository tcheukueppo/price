package Get::Article::Google;

use Mojo::UserAgent;
use Mojo::URL;

use Carp qw(croak carp);

my $no_google   = qr{https://(?!(?:(?:\w+\.)*google\.com))};
my $target_like = qr{
   (?|
      imgrefurl   = (?> [^&]+ )
    | (?:q|url|u) = ( $no_google (?>[^&]+) )
   )
}x;

sub new {
   carp "send key-value mojo ua options" if @_ % 2 == 0;
   my ($class, %args) = @_;

   my $self = {ua => Mojo::UserAgent->new()};
   foreach my $method (keys %args) {
      eval { $self->{ua}->$method($args{$method}) };
      carp "invalid 'Mojo::UserAgent' option: $method" if $@;
   }
   $self->{url} = Mojo::URL->new('https://www.google.com/search');
   $self->{ua}  = $ua;

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

   $self->{index} = 0;
   $self->{links} = [ $tx->result
                         ->dom
                         ->find('a[href]')
                         ->map(attr => 'href')
                         ->compact
                         ->grep(qr{[^/]})
                         ->map(sub { Mojo::URL->new($_)->query })
                         ->compact
                         ->map(sub { /$target_link/ ? $1 : ''  })
                         ->compact
                         ->head($n)
                         ->each
                    ];
   return 1;
}

sub get_content {
   my $self = shift;

   my $link = $self->{links} && $self->{links}[++$self->{index}];
   return unless $link;

   my $tx = $self->{ua}->get($link);
   return -1 if !$tx->result->is_success;

   my $content;

   return 
}
