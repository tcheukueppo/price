package Util;
use strict;
use warnings;

use feature qw(say);

sub ReadText {
   my $file = shift;

   open my $fh, '<', $file or die "$!\n";

   local $/;
   my ( $text, $av ) = ( <$fh> );
   while ( $text =~ /\G\s*@@\s*(?<a>[^@]+)/gs ) { 
      my $article = $+{a};

      push $av->{$article}->@*, $+{c} while $text =~ /\G\s*@\s*(?<c>(?>(?:\\@|[^@])+))/gsc;
   }

   return $av;
}

1;
