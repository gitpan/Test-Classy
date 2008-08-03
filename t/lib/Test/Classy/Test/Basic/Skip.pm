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

sub skip_3 : Tests(3) Skip(skipped by attribute) {
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

sub skip_5_abort : Tests(2) {
  my $class = shift;

  pass 'pass';

  return $class->abort_this_test('aborted');

  fail 'but this is to be skipped: 5-1';
}

sub skip_6_abort_alias : Tests(2) {
  my $class = shift;

  pass 'pass';

  # this is the alias of abort_this_test
  return $class->skip_this_test;

  fail 'but this is to be skipped: 6-1';
}

sub skip_7_abort : Test {
  my $class = shift;

  pass 'pass';

  return $class->abort_this_test('actually not aborted');
}

1;
