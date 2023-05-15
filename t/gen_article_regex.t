use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib './t/utils';
use Util;

BEGIN {
   use_ok('lib', './t/utils') or diag("could not add local lib dir");
   use_ok('Util')             or diag('where is Util?');
   use_ok('Get::Price')       or diag('Where is Get::Price?');
}

my $av = Util::ReadText('./t/contents/fruits.co') or diag('invalid content format?');

my %product_expect = (

     # Fruits
     'Blue Banana V2.10' => {regexs => [qr{}x, qr{}x,]},
     'B65.2k Red Orange' => {regexs => [qr{}x, qr{}x,]},

     # Other pruducts
                     );

like exception { Get::Price->new(undef, undef, UNKNOWN_CONFIG => 'what?') }, qr/^unknown configuration/, 'invalid configs';

my $test_product = sub {
   plan tests => 2;

   my $article = shift;
   my $price   = new_ok('Get::Price' => [$article, undef, MAX_OCCURENCE_PERC => 100]);

   # regex generation
   my $article_regex = $price->{article}{regexs};
   is_deeply($article_regex, $product_expect{$article}{regexs}, 'right generated regex') or explain $article_regex;

   # working on content
   foreach my $content (keys $av->{$article}->@*) {
      $price->{content} = $content;

      # more tests based on content
   }
};

foreach my $product (keys %product_expect) {
   subtest "testing product '$product'" => $test_product, $product unless exists $av->{$product};
}

done_testing();
