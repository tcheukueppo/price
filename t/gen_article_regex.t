use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib './t/utils';
use Util;

#BEGIN {
#   use_ok('lib', './t/utils') or diag("could not add local lib dir");
#   use_ok('Util')             or diag('where is Util?');
#   use_ok('Get::Price')       or diag('Where is Get::Price?');
#}

my $av = Util::ReadText('./t/contents/fruits.co') or diag('invalid content format?');

#my %expected = (
#   article_name => [
#      1 => []
#   ]
#);

my $test_article = sub {
   my $article = shift;
   my $price   = new_ok('Get::Price' => [$article]);

   #like exception { Get::Price->search_article(unknown => 'unknown') }, qr//, 'invalid config args';
   foreach my $content (keys $av->{$article}->@*) {
      $price->{contents} = $content;

      is_deeply($price->search_article(precision => 3, edit_distance => 4), $expected{$article};
   }
};

foreach my $article (keys %expected) {
   subtest "testing product '$article'" => $test_article, $product unless exists $av->{$product};
}

done_testing();
