#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;;

SKIP: {
    skip "not running on MSWin32", 1 unless $^O eq "MSWin32";

	is(
	scalar(`packed/perlpowertools.exe pwd`),
	scalar(`cd`),
	"packed/perlpowertools.exe pwd"
	);
}
