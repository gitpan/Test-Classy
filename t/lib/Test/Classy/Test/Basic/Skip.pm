package Test::Classy::Test::Basic::Skip;

use strict;
use warnings;
use Test::Classy::Base;

sub skip_1 : Test Skip {
  fail "but this is to be skipped: 1-1";
}

sub skip_2 : Test(2) Skip {
  fail "but this is to be skipped: 2-1";
  fail "but this is to be skipped: 2-2";
}

sub skip_3 : Tests(3) Skip {
  fail "but this is to be skipped: 3-1";
  fail "but this is to be skipped: 3-2";
  fail "but this is to be skipped: 3-3";
}

sub skip_4_partly : Tests(3) {
  pass "this should pass";

  SKIP: {
    skip 'skip inside a test', 1;
    fail "but this is to be skipped";
  }

  pass "this should pass, too";
}

1;
