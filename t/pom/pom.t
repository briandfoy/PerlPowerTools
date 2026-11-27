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

# https://github.com/briandfoy/PerlPowerTools/issues/1067
# "% of Full" is the illuminated fraction, not the phase angle. Expected
# values are for the nearest hour to the event (UTC), with a tolerance
# for the precision of the algorithm.
my @percent_table = (
	# label                                         date          percent  tolerance
	[ "issue 1067: 2026-11-14 01:19, 19.8% lit",    "2026111401", 20,      1 ],
	[ "new moon 2024-01-11 11:57",                  "2024011112",  0,      1 ],
	[ "first quarter 2024-01-18 03:53",             "2024011804", 50,      1 ],
	[ "full moon 2024-01-25 17:54",                 "2024012518", 100,     1 ],
	[ "last quarter 2024-02-02 23:18",              "2024020223", 50,      1 ],

	# Fred Espenak, "Phases of the Moon: 1901 to 2000", Universal Time
	# https://www.astropixels.com/ephemeris/phasescat/phases1901.html
	[ "full moon 1901-01-05 00:13",                 "1901010500", 100,     1 ],
	[ "last quarter 1901-01-12 20:38",              "1901011221", 50,      1 ],
	[ "new moon 1901-01-20 14:36",                  "1901012015",  0,      1 ],
	[ "first quarter 1901-01-27 09:52",             "1901012710", 50,      1 ],
	[ "last quarter 1980-10-01 03:18",              "1980100103", 50,      1 ],
	[ "full moon 1999-12-22 17:31",                 "1999122218", 100,     1 ],
	[ "last quarter 1999-12-29 14:04",              "1999122914", 50,      1 ],
	[ "new moon 2000-01-06 18:14",                  "2000010618",  0,      1 ],
	[ "first quarter 2000-01-14 13:34",             "2000011414", 50,      1 ],
	);

foreach my $tuple ( @percent_table ) {
	my( $label, $date, $percent, $tolerance ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, [ $date ], undef );
		my( $got ) = $result->{stdout} =~ /\((\d+)% of Full\)/;
		ok( defined $got, "found a percent in the output" ) or diag( $result->{stdout} );
		cmp_ok( abs( $got - $percent ), '<=', $tolerance, "percent for $date is $percent +/- $tolerance (got $got)" );
		is( $result->{exit}, 0, "exit status is 0" );
		};
	}

done_testing();
