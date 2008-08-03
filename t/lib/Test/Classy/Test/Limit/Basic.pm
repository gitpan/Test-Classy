package Test::Classy::Test::Limit::Basic;

use strict;
use warnings;
use Test::Classy::Base;

sub limit_test : Test Target {
  pass 'this test will be executed';
}

sub not_targeted : Test {
  fail 'this test should be skipped';
}

1;
