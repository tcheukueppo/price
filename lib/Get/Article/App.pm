package Get::Article::App;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor;

use Get::Article;
use Get::Article::Exchange;
use Get::Article::Google;

use Mojo::UserAgent;

# Debug
use feature qw(say);
use Data::Dumper;

my $options = {
               article => {
                           min_jaro   => 0.8,
                           token_dist => 1,
                           token_perc => 80,
                           nkfd       => 0,
                          },
               others => {
                          verbose    => 0,
                          down_image => 1,
                          sql        => 0,
                          contents   => 5,
                          color      => 1,
                         },
               mojo_ua => {
                           proxy           => '',
                           connect_timeout => 10,
                           max_redirects   => 0,
                           request_timeout => 0,
                          },
              };

my $ua       = Mojo::UserAgent->new;
my $google   = Get::Article::Google->new($ua);
my $exchange = Get::Article::Exchange->new($ua);
my $article  = Get::Article->new;

GetOptions(
           '--verbose'         => \$options->{others}{verbose},
           'sq|sql-insert=s'   => \$options->{others}{sql},
           'j|min-jaro=i'      => sub { 1 },
           'i|involved=i'      => sub { 1 },
           'v|precision=i'     => \$options->{article}{token_dist},
           's|sensitive'       => \$options->{article}{nkfd},
           'd|download-image'  => \$options->{others}{down_image},
           'c|color'           => \$options->{others}{color},
           'n|content-count=i' => \$options->{others}{contents},
           't|con-timeout=i'   => \$options->{mojo_ua}{connect_timeout},
           'r|max-redirect=i'  => \$options->{mojo_ua}{max_redirects},
           'p|proxy=s'         => \$options->{mojo_ua}{proxy},
           'rt|req-timeout=i'  => \$options->{mojo_ua}{request_timeout},
          );

sub app {

   # ...
}

1;
