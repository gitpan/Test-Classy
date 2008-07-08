package Test::Classy::Test::Basic::Todo;

use strict;
use warnings;
use Test::Classy::Base;

sub todo_1 : Test TODO {
  fail "but this is a todo test: 1-1";
}

sub todo_2 : Test(2) TODO {
  fail "but this is a todo test: 2-1";
  fail "but this is a todo test: 2-2";
}

sub todo_3 : Tests(3) TODO {
  fail "but this is a todo test: 3-1";
  fail "but this is a todo test: 3-2";
  fail "but this is a todo test: 3-3";
}

sub todo_4_partly : Tests(3) {
  pass "this should pass";

  TODO: {
    local $TODO = 'this is not implemented';
    fail "this is a todo test";
  }

  pass "this should pass, too";
}

1;
