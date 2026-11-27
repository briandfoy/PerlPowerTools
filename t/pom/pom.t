use strict;
use warnings;
use Test::More;

require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

# https://github.com/briandfoy/PerlPowerTools/issues/1067
# Julian days start at noon, so midnight on a date ends in .5.
# 1980 January 0.0 (1979-12-31 00:00) is the program's EPOCH.
my @table = (
	[ "1980 January 0.0 is EPOCH",  "1979123100", "2444238.5" ],
	[ "2000 January 1.0",           "2000010100", "2451544.5" ],
	[ "Julian calendar date",       "1582100400", "2299159.5" ],
	[ "Gregorian calendar date",    "1582101500", "2299160.5" ],
	);

foreach my $tuple ( @table ) {
	my( $label, $date, $julian ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, [ '-d', $date ], undef );
		like( $result->{stdout}, qr/^julian day = \Q$julian\E$/m, "julian day for $date is $julian" );
		is( $result->{exit}, 0, "exit status is 0" );
		};
	}

done_testing();
