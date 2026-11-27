use strict;
use warnings;
use Test::More;

require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

# https://github.com/briandfoy/PerlPowerTools/issues/408
# -w sets the page width, so each of 2 columns is 20/2 = 10 wide.
# -l 12 leaves 2 body lines per page (5 header, 5 trailer), so
# "a" and "b" fill column 1 and "c" and "d" fill column 2.
subtest "issue 408: -w sets the page width" => sub {
	my $result = run_command( $Script, [ qw(-2 -w 20 -l 12) ], "a\nb\nc\nd\n" );
	like( $result->{stdout}, qr/^a {9}c {9}$/m, "first line, columns 10 wide" );
	like( $result->{stdout}, qr/^b {9}d {9}$/m, "second line, columns 10 wide" );
	is( $result->{exit}, 0, "exit status is 0" );
	};

done_testing();
