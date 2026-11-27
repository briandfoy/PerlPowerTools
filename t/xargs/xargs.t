use strict;
use warnings;
use Test::More;

require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

# https://github.com/briandfoy/PerlPowerTools/issues/1072
my $input = "hi\nnew stuff\nnew stuff2\n";

my @table = (
	[ "-n 1, trailing blank line",    "$input\n", [qw( -n 1 )], "hi\nnew\nstuff\nnew\nstuff2\n" ],
	[ "-n 1, no trailing blank line", $input,     [qw( -n 1 )], "hi\nnew\nstuff\nnew\nstuff2\n" ],
	[ "-n 2, leftover args at EOF",   $input,     [qw( -n 2 )], "hi new\nstuff new\nstuff2\n"   ],
	[ "no -n",                        $input,     [],           "hi new stuff new stuff2\n"     ],
	);

foreach my $tuple ( @table ) {
	my( $label, $stdin, $args, $stdout ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, $args, $stdin );
		is( $result->{stdout}, $stdout, "stdout is as expected for args <@$args>" );
		is( $result->{exit},   0,       "exit status is 0" );
		};
	}

done_testing();
