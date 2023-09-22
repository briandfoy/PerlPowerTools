use strict;
use warnings;

use Test::More;

use File::Spec;

my $program = File::Spec->catfile( qw(blib script seq) );

subtest 'check file' => sub {
	ok( -e $program, "$program exists" );
	SKIP: {
		skip "This test isn't for Windows", 1 if $^O eq 'MSWin32';
		ok( -x $program, "$program is executable" );
		}
	};

my @args = (
	[ [qw(1 10)],           join( "\n", 1 .. 10 ) . "\n" ],
	[ [qw( -s - 1 10 )],    join( '-', 1 .. 10 ) . "\n" ],
	[ [qw( -f "%o" 1 10 )], join( "\n", map { sprintf '%o', $_ } 1 .. 10 ) . "\n" ],
	[ [qw( -2 1 5 )],       join( "\n", -2 .. 5 ) . "\n" ],
	[ [qw( -2 2 6 )],       join( "\n", qw(-2 0 2 4 6) ) . "\n" ],
	);

foreach my $tuple ( @args ) {
	my( $args, $expected ) = @$tuple;

	my $output = qx/"$^X" $program @$args/;

	is( $output, $expected, "seq is right for <@$args>" );
	}

done_testing();
