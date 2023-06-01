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
                          currency   => '',
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

sub currency {
   $_[1] = uc $_[1];
   grep { $_[1] eq $_ } @Get::Article::Currency::CODES or $die->('unknown currency osi codes');
   $options->{others}{currency} = $_[1];
}

GetOptions(
           'p|proxy=s'           => \&proxy,
           'j|min-jaro=i'        => \&jaro,
           'h|help'              => \&pod2usage,
           'r|retries=i'         => \$options->{others}{retries},
           'sq|sql-insert=s'     => \$options->{others}{sql},
           'p|price'             => \$options->{article}{price},
           'v|precision=i'       => \$options->{article}{token_dist},
           's|sensitive'         => \$options->{article}{nkfd},
           'i|in=s'              => \&currency,
           'verbose'             => \$options->{others}{verbose},
           'w|number-websites=i' => \$options->{others}{websites},
           'd|download-image'    => \$options->{others}{down_image},
           'color!'              => \$options->{others}{color},
           'n|number-contents=i' => \$options->{others}{contents},
           'mr|max-redirect=i'   => \$options->{mojo_ua}{max_redirects},
           'ct|con-timeout=i'    => \$options->{mojo_ua}{connect_timeout},
           'rt|req-timeout=i'    => \$options->{mojo_ua}{request_timeout},
          )
  or pod2usage(1);

@ARGV or $die->('please specify an article name');

my $lang_re = do {
   local $" = '|';
   my @dot = qw();

   qr{^(?:@dots)$};
};

my $ua      = Mojo::UserAgent->new;
my $google  = Get::Article::Google->new($ua);
my $article = Get::Article->new;

length $options->{mojo_ua}{$_} and $ua->$_($options->{mojo_ua}{$_}) foreach keys %{$options->{mojo_ua}};
$options->{others}{retries} = 3 if $options->{others}{retries} < 0;

ARTICLE: foreach my $article (@ARGV) {
   my $tries = -1;

   $article->article($article);
   do {
      my $status = 0;
      eval { $status = $google->google($article, $options->{others}{websites} <= 0 ? 4 : $options->{others}{websites}) };
      $status ? last : next ARTICLE unless $@;
      ++$tries == $options->{others}{retries} and exit 1;
      $warn->("$@, retrying...");
   } while 1;

   $tries = -1;
 LINK: while ((my $link = $google->next) != -1) {
      my $contents;

      do {
         eval { $contents = $google->get_contents };
         $content ? last : next LINK unless $@;
         ++$tries == $options->{others}{retries} and exit 1;
         $warn->("$@, retrying...");
      } while 1;

      my $lang = $contents->{lang};
      $article->contents($contents->{text});
      $contents = $article->search_article(%{$options->{article}});

      # pick best article description
      my $content = (sort { $b->{jaro} <=> $a->{jaro} || $a->{impure} <=> $b->{impure} } @$contents)[0];
      if ($options->{article}{price} && $content->{price}) {
         local *_ = \$content->{price};
         s/\s+/_/g;
         $lang =~ $lang_re ? s/,/_/g : s/,/./;
      }

      # currency conversion?
      if (   $options->{others}{currency}
          && !exists $Get::Article::Currency::SYMBOLS->{$content->{price}[1]}
          && $content->{price}[1] ne $options->{others}{currency}) {

         $tries               = -1;
         $content->{price}[1] = $options->{others}{currency};
         $content->{price}[0] = do {
            my $price;
            my $exchange = Get::Article::Exchange->new($ua);
            do {
               eval { $price = $exchange->convert(@{$content->{price}}, $options->{others}{currency}) };
               last unless $@;
               ++$tries == $options->{others}{retries} and exit 1;
               $warn->("$@, retrying..");
            } while 1;
            $price;
         };
      }

      if ($options->{others}{sql}) {
         ## ...
      }
      else {
         print "Price: ", color('blue') if $options->{others}{color};
         sprintf "%.2f %s", @{$content->{price}};
         print color('reset'), "\n";
      }
   }
}

1;
