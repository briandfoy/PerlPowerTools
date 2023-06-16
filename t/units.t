#!/usr/bin/perl

# units.t - test for script units

use strict;
use warnings;

use Test::More;

run_tests();

sub run_tests {
    my $class = require './bin/units';

	subtest sanity => sub {
		can_ok $class, 'test'
	};

	my @tables = (
		calendar_table(),
		distance_table(),
		volume_table(),
	);

	run_table($class, $_) for @tables;

	temp_test($class);

    return;
}

done_testing();

sub calendar_table {
	my $table = [
		"calendar",
		[qw(month year 12), round(1/12)]
	];
}

sub distance_table {
	my $table = [
		"distance",
		# have want p q
		[ qw( m m 1 1 ) ],
		[ qw( m cm 0.01 100 ) ],
		[ qw( meters feet 0.3048 3.28084 ) ],
		[ qw( meters/s furlongs/fortnight 0.00016631 6012.88 ) ],
		[ '1|2 in', 'cm', qw( 0.787402 1.27 ) ],
	];
}

sub run_table {
	my( $class, $table ) = @_;
	my $label = shift @$table;

	subtest $label => sub {
		foreach my $tuple ( @$table ) {
			my( $have, $want, $expected, $inverse ) = @$tuple;
			my %got = $class->test( $have, $want );
			is round($got{'p'}), $expected, "$have -> $want";
			is round($got{'q'}), $inverse, "$want -> $have";
		}
	};
}

sub temp_test {
	my($class) = @_;

	subtest temperature => sub {
		my @table = (
			[qw(      K        K      0    )  ],
			[qw(      K        C   -273.15 )  ],
			[qw(      K        R      0    )  ],
			[qw(      C        K    273.15 )  ],
			[qw(      R        K      0    )  ],
			[qw(      C        F     32    )  ],
			[qw(     0C        F     32    )  ],
			[    '100 C',     'F', '212'      ],
			[    '-40 C',     'F', '-40'      ],
			[    '98.6F',     'C',  '37'      ],
			[qw( 255.37K       C    -17.78  ) ],
			[    '99.9836 C', 'K', '373.134'  ],
		);

		foreach my $tuple ( @table ) {
			my( $have, $want, $expected ) = @$tuple;
			my %got = $class->test( $have, $want );
			is round($got{t}), $expected, "$have -> $want";
		}

    	my %got = $class->test('-17.78C','F');
    	ok round($got{t}) < 0.00001;
	};
}

sub volume_table {
	my $table = [
		"volume",
		[qw(cm3 gallons 3785.41 0.000264172)]
	];
}

sub round {
    sprintf '%.6g', $_[0];
}
