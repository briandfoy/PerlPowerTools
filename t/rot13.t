use strict;
use warnings;

use Test::More;

use File::Spec::Functions;
use IPC::Open2;

my $program = catfile( qw(bin rot13) );

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
