package Test::Classy::Test::Basic::SkipClassDeprecated;

use strict;
use warnings;
use Test::Classy::Base;

sub initialize {
  my $class = shift;

  # deprecated
  $class->skip_the_rest;
}

sub failing_test2 : Test {
  fail "but this is to be skipped";
}

1;
