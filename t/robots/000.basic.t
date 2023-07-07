use strict;
use warnings;

use Test::More;

my $program = 'bin/robots';

SKIP: {
	my $rc = eval { require Curses; 1 };
	skip "$program needs at Curses, but we don't have that. Skipping...", 1
		unless $rc;
	require './t/lib/common.pl';
	sanity_test($program);
	}

done_testing();
