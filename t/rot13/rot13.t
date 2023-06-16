use strict;
use warnings;

use Test::More;

use File::Spec;

my $program = File::Spec->catfile( qw(blib script rot13) );

subtest 'check file' => sub {
	ok( -e $program, "$program exists" );
	SKIP: {
		skip "This test isn't for Windows", 1 if $^O eq 'MSWin32';
		ok( -x $program, "$program is executable" );
		}
	};

my @strings = (
	[ 'abcdefghijklmnopqrstuvwxyz', 'nopqrstuvwxyzabcdefghijklm' ],
	[ 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'NOPQRSTUVWXYZABCDEFGHIJKLM' ],
	[ 'Hello World!',               'Uryyb Jbeyq!'               ],
	[ "Hello\nWorld!",              "Uryyb\nJbeyq!"              ],
	);

foreach my $tuple ( @strings ) {
	my( $input, $expected ) = @$tuple;

	{ open my $fh,'>', 't/temp-rot13-in' or die "Error: $!"; print $fh $input; }
	`$program <t/temp-rot13-in >t/temp-rot13-out`;
	my $output = do { open my $fh, '<', 't/temp-rot13-out'; local $/; <$fh> };
	unlink 't/temp-rot13-in', 't/temp-rot13-out';

	is( $output, $expected, 'Rot13 is right' );
	}

done_testing();
