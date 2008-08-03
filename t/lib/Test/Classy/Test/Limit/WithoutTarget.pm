package Test::Classy::Test::Limit::WithoutTarget;

use strict;
use warnings;
use Test::Classy::Base;

sub not_targeted_at_all : Test {
  fail 'this test should be skipped';
}

1;
