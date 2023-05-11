package Util;

use strict;
use warnings;

sub ReadText {
   my $file = shift;

   local $/;
   open my $fh, '<', $file or die "$!\n";

   my ( $text, $av ) = ( <$fh> );
   while ( $text =~ /\G\s*@@\s*(?<a>[^@]+)(?<!\s)\s*/g ) {
      my $article = $+{a};

      push $av->{$article}->@*, $+{c} while $text =~ /\G\s*@\s*(?<c>(?:\\@|[^@]+))(?<!\s)\s*/gc;
   }

   return $av;
}

1;
