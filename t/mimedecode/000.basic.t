use strict;
use warnings;

use Test::More;

my $program = 'bin/mimedecode';
my $minimum_version = 5.012;

SKIP: {
	skip "$program needs at least Perl $minimum_version. Skipping...", 1
		unless $] >= $minimum_version;
	require './t/lib/common.pl';
	sanity_test('bin/mimedecode');
	}

done_testing();
