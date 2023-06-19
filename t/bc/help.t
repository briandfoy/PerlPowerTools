#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IPC::Run3 qw(run3);

run3(
	[ $^X, 'bin/bc', '-h' ],
	undef, \my @output
	);
is( $? >> 8, 0, 'Exits with 0' );

done_testing();
