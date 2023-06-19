#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IPC::Run3 qw(run3);

my $welcome_pattern = qr/\Abc \d.\d+ \(PerlPowerTools\)/;

subtest 'not quiet' => sub {
	run3(
		[ $^X, 'bin/bc', '-' ],
		\"quit\n", \my $output, \undef
		);
	is( $? >> 8, 0, 'Exits with 0' );
	like $output, $welcome_pattern, 'Without -q, the welcome message shows up';
	};

subtest 'quiet' => sub {
	run3(
		[ $^X, 'bin/bc', '-q', '-' ],
		\"quit\n", \my $output, \undef
		);
	is( $? >> 8, 0, 'Exits with 0' );
	unlike $output, $welcome_pattern, 'With -q, the welcome message does not show up';
	};

done_testing();
