#!/usr/bin/perl

use Test::More;
use Test::Pod;

require './t/lib/common.pl';

my @programs = programs_to_test();

subtest pod => sub {
	foreach my $program ( @programs ) {
		pod_file_ok( $program, "Valid POD in <$program>" );
		}
	};

done_testing();
