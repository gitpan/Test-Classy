package Test::Classy::Base;

use strict;
use warnings;
use base qw( Class::Data::Inheritable );
use Test::More ();
use Class::Inspector;

sub import {
  my ($class, @flags)  = @_;
  my $caller = caller;

  if ( $class ne __PACKAGE__ ) {
    return unless grep { $_ eq 'base' } @flags;
  }

  no strict 'refs';
  push @{"$caller\::ISA"}, $class;

  # XXX: not sure why but $TODO refused to be exported well
  *{"$caller\::TODO"} = \$Test::More::TODO;

  foreach my $export ( @Test::More::EXPORT ) {
    next if $export =~ /^\W/;
    *{"$caller\::$export"} = \&{"Test::More\::$export"};
  }

  if ( grep { $_ eq 'ignore' } @flags ) {
    ${"$caller\::_ignore"} = 1;
  }

  if ( $class eq __PACKAGE__ ) {
    $caller->mk_classdata( _tests => {} );
    $caller->mk_classdata( _plan => 0 );
    $caller->mk_classdata( test_name => '' );
  }
}

sub MODIFY_CODE_ATTRIBUTES {
  my ($class, $code, @attrs) = @_;

  my %stash;
  foreach my $attr ( @attrs ) {
    if ( $attr eq 'Test' ) {
      $stash{plan} = 1;
    }
    elsif ( my ($dummy, $plan) = $attr =~ /^Tests?\((['"]?)(\d+|no_plan)\1\)$/ ) {
      $stash{plan} = $plan;
    }
    elsif ( my ($type, $dummy2, $reason) = $attr =~ /^(Skip|TODO)(?:\((['"]?)(.+)\)\2)?$/ ) {
      $stash{$type} = $reason;
    }
    else {
      $stash{$attr} = 1;
    }
  }
  return unless $stash{plan};

  if ( $stash{plan} eq 'no_plan' ) {
    Test::More::plan 'no_plan' unless Test::More->builder->{Have_Plan};
    $stash{plan} = 0;
  }

  $class->_plan( $class->_plan + $stash{plan} );

  $stash{code} = $code;

  # At this point, the name looks like CODE(...)
  # we'll make it human-readable later, with class inspection
  $class->_tests->{$code} = \%stash;

  return;
}

sub _limit {
  my ($class, @monikers) = @_;

  my $tests = $class->_tests;
  my $reason = 'tests only ' . ( join ', ', @monikers );

LOOP:
  foreach my $name ( keys %{ $tests } ) {
    foreach my $moniker ( @monikers ) {
      next LOOP if exists $tests->{$name}->{$moniker};
    }
    $tests->{$name}->{Skip} = $reason;
  }
}

sub _should_be_ignored {
  my $class = shift;

  { no strict 'refs';
    if ( ${"$class\::_ignore"} ) {
      SKIP: {
        Test::More::skip 'a base class, not to test', $class->_plan;
      }
      return 1;
    }
  }
}

sub _find_symbols {
  my $class = shift;

  my $methods = Class::Inspector->methods($class, 'expanded');

  my %symbols;
  foreach my $entry ( @{ $methods } ) {
    $symbols{$entry->[3]} = $entry->[2];  # coderef to sub name
  }
  return %symbols;
}

sub _run_tests {
  my ($class, @args) = @_;

  return if $class->_should_be_ignored;

  my %sym = $class->_find_symbols;

  $class->initialize(@args);

  my $tests = $class->_tests;

  foreach my $name ( sort { $sym{$a} cmp $sym{$b} } grep { $sym{$_} } keys %{ $tests } ) {
    next if $sym{$name} =~ /^(?:initialize|finalize)$/;

    if ( my $reason = $class->_should_skip_the_rest ) {
      SKIP: { Test::More::skip $reason, $tests->{$name}->{plan}; }
      next;
    }

    $class->_run_test( $tests->{$name}, $sym{$name}, @args );
  }

  $class->finalize(@args);
}

sub _run_test {
  my ($class, $test, $name, @args) = @_;

  $class->test_name( $name );

  if ( exists $test->{TODO} ) {
    my $reason = defined $test->{TODO}
      ? $test->{TODO}
      : "$name is not implemented";

    if ( exists $test->{Skip} ) {  # todo skip
      TODO: {
        Test::More::todo_skip $reason, $test->{plan};
      }
    }
    else {
      TODO: {
        no strict 'refs';
        local ${"$class\::TODO"} = $reason; # perl 5.6.2 hates this
        $test->{code}($class, @args);
      }
    }
    return;
  }
  elsif ( exists $test->{Skip} ) {
    my $reason = defined $test->{Skip}
      ? $test->{Skip}
      : "skipped $name";
    SKIP: { Test::More::skip $reason, $test->{plan}; }
    return;
  }

  $test->{code}($class, @args);
}

sub skip_the_rest {
  my ($class, $reason) = @_;

  no strict 'refs';
  ${"$class\::_skip_the_rest"} = $reason || 'for some reason';
}

sub _should_skip_the_rest {
  my $class = shift;

  no strict 'refs';
  return ${"$class\::_skip_the_rest"};
}

sub initialize {}
sub finalize {}

1;

__END__

=head1 NAME

Test::Classy::Base

=head1 SYNOPSIS

  package MyApp::Test::ForSomething;
  use Test::Classy::Base;

  __PACKAGE__->mk_classdata('model');

  sub initialize {
    my $class = shift;

    eval { require 'Some::Model'; };
    $class->skip_the_rest('Some::Model is required') if $@;

    my $model = Some::Model->connect;

    $class->model($model);
  }

  sub mytest : Test {
    my $class = shift;
    ok $class->model->find('something'), $class->test_name." works";
  }

  sub finalize {
    my $class = shift;
    $class->model->disconnect if $class->model;
    $class->model(undef);
  }

=head1 DESCRIPTION

This is a base class for actual tests. See L<Test::Classy> for basic usage.

=head1 CLASS METHODS

=head2 skip_the_rest

If you called this with a reason why you want to skip (unsupported OS or lack of modules, for example), all the remaining tests in the package will be skipped.

=head2 initialize

This is called before the tests runs. You might want to set up database or something like that here. You can store initialized thingy as a class data (via Class::Data::Inheritable), or as a package-wide variable, maybe. Note that you can set up thingy in a test script and pass it as an argument for each of the tests instead.

=head2 finalize

This method is (hopefully) called when all the tests in the package are done. You might also want provide END/DESTROY to clean up thingy when the tests should be bailed out.

=head2 test_name

returns the name of the test running currently. Handy to write a meaningful test message.

=head1 NOTES FOR INHERITING TESTS

You may want to let tests inherit some base class (especially to reuse common initialization/finalization). You can use good old base.pm (or parent.pm) to do this, though you'll need to use Test::More and the likes explicitly as base.pm doesn't export things:

  package MyApp::Test::Base;
  use Test::Classy::Base;
  use MyApp::Model;

  __PACKAGE__->mk_classdata('model');

  sub initialize {
    my $class = shift;

    $class->model( MyApp::Model->new );
  }

  package MyApp::Test::Specific;
  use base qw( MyApp::Test::Base );
  use Test::More;  # you'll need this.

  sub test : Test { ok shift->model->does_fine; }

You also can add 'base' option while using your base class. In this case, all the methods will be exported.

  package MyApp::Test::Specific;
  use MyApp::Test::Base 'base';

  sub test : Test { ok shift->model->does_fine; }

When your base class has some common tests to be inherited, and you don't want them to be tested in the base class, add 'ignore' option when you use Test::Classy::Base:

  package MyApp::Test::AnotherBase;
  use Test::Classy::Base 'ignore';

  sub not_for_base : Test { pass 'for children only' };

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
