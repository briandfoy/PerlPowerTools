use File::Spec::Functions;
use IPC::Run3 qw(run3);

use Test::More;

require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

# taken form Michael Mikonos's tests in https://github.com/briandfoy/PerlPowerTools/pull/403
my @table = (
	[ "positive -b value",  'a:b:c:d', [qw( -b 3        )], "b\n"   ],
	[ "negative -b value",  'a:b:c:d', [qw( -b -3       )], "a:b\n" ],
	[ "-b range",           'a:b:c:d', [qw( -b 2-3      )], ":b\n"  ],
	[ "positive -f value",  'a:b:c:d', [qw( -d : -f 2   )], "b\n"   ],
	[ "negative -f value",  'a:b:c:d', [qw( -d : -f -2  )], "a:b\n" ],
	[ "-f range",           'a:b:c:d', [qw( -d : -f 2-3 )], "b:c\n" ],
	);


foreach my $tuple ( @table ) {
	my( $label, $stdin, $args, $stdout ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, $args, $stdin );
		is( length($stdout), length($result->{stdout}), "received and expected data lengths are the same" );
		is( $result->{stdout}, $stdout, "stdout is as expected for args <@$args>" );
		is( $result->{error},  $stderr, "stderr is as expected for args <@$args>" );
		}
	}

done_testing();
