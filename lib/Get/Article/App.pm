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
                           price      => 1,
                          },
               others => {
                          verbose    => 0,
                          down_image => 1,
                          sql        => 0,
                          websites   => 4,
                          contents   => 5,
                          color      => 1,
                          retries    => 2,
                         },
               mojo_ua => {
                           proxy           => '',
                           connect_timeout => 10,
                           max_redirects   => 0,
                           request_timeout => 0,
                          },
              };

my $die = sub {
   warn "$0: $_[0]\n";
   pod2usage(1);
};

my $warn = sub {
   print STDERR color('red') if $options->{others}{color};
   warn "$0: $_[0]\n";
   print color('reset');
};

sub proxy {
   $_[1] =~ m{^socks://[^:]+(?::\d+)?$} or $die->('invalid proxy url');
   $options->{mojo_ua}{proxy} = $_[1];
}

sub jaro {
   0.7 < $_[1] <= 1 or $die->('min jaro: 0.7, max jaro: 1');
   $options->{article}{min_jaro} = $_[1];
}

GetOptions(
           'p|proxy=s'           => \&proxy,
           'j|min-jaro=i'        => \&jaro,
           'verbose'             => \$options->{others}{verbose},
           'w|number-websites=i' => \$options->{others}{websites},
           'h|help'              => \&pod2usage,
           'r|retries=i'         => \$options->{others}{retries},
           'sq|sql-insert=s'     => \$options->{others}{sql},
           'p|price'             => \$options->{article}{price},
           'v|precision=i'       => \$options->{article}{token_dist},
           's|sensitive'         => \$options->{article}{nkfd},
           'd|download-image'    => \$options->{others}{down_image},
           'color!'              => \$options->{others}{color},
           'n|number-contents=i' => \$options->{others}{contents},
           'mr|max-redirect=i'   => \$options->{mojo_ua}{max_redirects},
           'ct|con-timeout=i'    => \$options->{mojo_ua}{connect_timeout},
           'rt|req-timeout=i'    => \$options->{mojo_ua}{request_timeout},
          )
  or pod2usage(1);

@ARGV or $die->('please specify an article name');

my $ua       = Mojo::UserAgent->new;
my $google   = Get::Article::Google->new($ua);
my $exchange = Get::Article::Exchange->new($ua);
my $article  = Get::Article->new;

length $options->{mojo_ua}{$_} and $ua->$_($options->{mojo_ua}{$_}) foreach keys %{$options->{mojo_ua}};

$options->{others}{retries} = 3 if $options->{others}{retries} < 0;
foreach my $article (@ARGV) {
   my $tries = -1;

   do {
      last if $google->google($article, $options->{others}{websites} <= 0 ? 4 : $options->{others}{websites});
      $warn->("failed to google $article, retrying...");
   } until ++$tries == $options->{others}{retries};

   my $i = 1;
   while ($i <= @{$google->{links}}) {
      my $contents = $google->get_contents;
      $article->article($article)->contents($contents);
      $contents = $article->search_article(%{$options->{article}});

      # pick best content
      my $content = (sort { $b->{jaro} <=> $a->{jaro} } @$contents)[0];

   }
}

1;
