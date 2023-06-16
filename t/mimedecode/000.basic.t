use strict;
use warnings;

use Test::More;

if( $] >= 5.012 ) {
	require './t/lib/common.pl';
	sanity_test();
	}
else {
	pass("Not testing under Perl $]");
	}

done_testing();
