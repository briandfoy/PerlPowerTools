#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

require './t/lib/common.pl';

my $test_sub = do {
	my @required_meta_keys = qw(Name Description Author License);
	sub {
		my( $program ) = @_;
		ok -e $program, "$program exists";

		my $program_meta = extract_meta( $program );

		subtest "required keys" => sub {
			ok( exists $program_meta->{$_}, "has $_ key" ) for @required_meta_keys;
			};
		};
	};

run_program_test( 'meta' => $test_sub );

done_testing();
