package Test::Classy::Test::Basic::Plain;

use strict;
use warnings;
use Test::Classy::Base;

sub plain_1 : Test {
  pass "first test";
}

sub plain_2 : Tests(2) {
  pass "second test";
  pass "third test";
}

sub plain_3 : Tests(3) {
  pass "fourth test";
  pass "fifth test";
  pass "sixth test";
}

1;
