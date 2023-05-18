package Article::Google;

use Mojo::UserAgent;
use Carp qw(croak);

sub new {
   my ($class, %args) = @_;

   my $ua = Mojo::UserAgent->new();
   foreach my $method (keys %args) {
      croak "invalid config: $method" if $method !~ /^connect_timeout|max_redirect|proxy$/;
      $ua = eval "\$ua->$method('$args{$method}')";
   }

   bless {
          google => 'https://www.google.com/search?q=%s',
          ua     => $ua,
         }, $class;
}

sub fetch_links {
   my ($self, $n, $article) = @_;

   $n //= 4;
   my $dom = $self->{ua}->get(sprintf $self->{google}, $article)->result;

   # fetch links
}

sub get_content {
   my $self = shift;

   # iterate over them and return it
}
