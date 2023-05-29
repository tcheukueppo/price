package Get::Article::App;

use strict;
use warnings;
use utf8;

no warnings 'utf8';

use Getopt::Long;
use Get::Article;
use Get::Article::Exchange;
use Get::Article::Google;

use Mojo::UserAgent;

# Debug
use feature qw(say);
use Data::Dumper;

sub app {
   my $article = $ARGV[0];
   my $ua      = Mojo::UserAgent->new;
   my $g       = Get::Article::Google->new($ua);

   if ($g->google($article)) {
      my $contents = $g->get_contents;
      if ($contents) {
         @$contents = map { $_->{text} } @$contents;
         my $result = Get::Article->new($article, $contents)->search_article(
                                                                             price      => 0,
                                                                             nkfd       => 1,
                                                                             jaro       => 0.9,
                                                                             token_dist => 1,
                                                                            );
         say Dumper $result;
      }
      else {
         say "Failed to get results";
      }
   }
   else {
      say "Faild to google";
   }

}

1;
