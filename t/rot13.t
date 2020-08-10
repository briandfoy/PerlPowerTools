use strict;
use warnings;

use Test::More;

use File::Spec;
use IPC::Open2;

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
	my $pid = open2( my $reader, my $writer, $program );
	print { $writer } $input;
	close $writer;

	my $output = do { local $/; <$reader> };

	is( $output, $expected, 'Rot13 is right' );
	}

done_testing();
