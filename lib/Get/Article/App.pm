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
