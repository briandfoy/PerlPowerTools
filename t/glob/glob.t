use 5.006;
use strict;

use Test::More 1;

BEGIN {
	package Local::Glob;
	our @ISA = qw(PerlPowerTools::glob);

	sub exit {
		( my $class, $Local::Glob::code, $Local::Glob::message ) = @_;
		}

	sub output_list {
		( my $class, $Local::Glob::array, $Local::Glob::separator ) = @_;
		$Local::Glob::separator = "\n" unless defined $Local::Glob::separator;
		}
}

sub clear {
	$Local::Glob::code    = undef;
	$Local::Glob::message = undef;
	$Local::Glob::array   = [];
	}

my $class = 'Local::Glob';

my $NO_MATCH_MESSAGE = 'glob: No match.';
my $UNMATCHED_BRACE_MESSAGE = q(Missing '}'.);

use constant EX_SUCCESS       => 0;
use constant EX_MISSING_BRACE => 1;
use constant EX_NO_MATCHES    => 1;
use constant EX_FAILURE       => 2;

subtest setup => sub {
	use lib qw(.);
	require_ok( 'bin/glob' );
	can_ok( $class, 'run' );
	};

subtest 'no args' => sub {
	clear();
	$class->run();

	is $Local::Glob::code, EX_FAILURE, 'exit code is error';
	is scalar @$Local::Glob::array, 0, 'there are not results';
	is "$Local::Glob::message", '', 'there is no output message';
	};

subtest 'no wildcards' => sub {
	clear();
	my @args = qw(foo bar);

	$class->run(@args);

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply $Local::Glob::array, [@args], 'list as expected';
	};

subtest 'one arg, some matches' => sub {
	clear();
	my @args = qw(t/lib/*);

	$class->run(@args);

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[map { "t/lib/$_" } qw(common.pl utils.pm)],
		'list as expected';
	};

subtest 'one arg, no matches' => sub {
	clear();

	my @args = qw(t/not_there/*);

	$class->run(@args);

	is $Local::Glob::code, EX_NO_MATCHES, 'exit code is no matches';
	is scalar @$Local::Glob::array, 0, 'there are no results'
		or diag( explain($Local::Glob::array) );
	is "$Local::Glob::message", $NO_MATCH_MESSAGE, 'there is no output message';
	};

subtest 'two arg, some matches' => sub {
	clear();
	my @args = qw(t/lib/* t/glob/*);

	$class->run(@args);

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ 't/glob/glob.t', map { "t/lib/$_" } qw(common.pl utils.pm)],
		'list as expected';
	};

subtest 'one tilde, no wildcard' => sub {
	clear();
	my @args = qw(~nouserxyz456);

	$class->run(@args);

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ @args ],
		'list as expected';
	};

subtest 'two tilde, no wildcard' => sub {
	clear();
	my @args = qw(~nouserxyz456 ~nousersafgadfg);

	$class->run(@args);

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @args ],
		'list as expected';
	};

subtest 'just braces' => sub {
	clear();
	my @args = qw( {} );
	$class->run( @args );

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @args ],
		'list as expected';
	};

subtest 'unclosed left brace' => sub {
	clear();
	my @args = ( '{a,b' );
	$class->run( @args );

	is $Local::Glob::code, EX_MISSING_BRACE, 'exit code is an error';
	is scalar @$Local::Glob::array, 0, 'there are no results';
	is "$Local::Glob::message", $UNMATCHED_BRACE_MESSAGE, 'there is no output message';
	};

subtest 'unpaired right brace' => sub {
	clear();
	my @args = ( '}a{b,c}' );
	my @expected = qw( }ab }ac );

	$class->run( @args );

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is scalar @$Local::Glob::array, scalar @expected, 'got expected number of results';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @expected ],
		'list as expected';
	};

subtest 'nested braces' => sub {
	clear();
	my @args = ( '{a{b,c},d}' );
	my @expected = qw( ab ac d );

	$class->run( @args );

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @expected ],
		'list as expected';
	};

subtest 'brace in charclass' => sub {
	# this one is weird, but this is how csh_glob works
	# the real csh glob on macOS, Raspberry reports a missing }
	# but I think that is also a bug after looking at the OpenBSD
	# source.
	clear();
	my @args = ( '[{]' );
	my @expected = qw( [ );

	$class->run( @args );

	is $Local::Glob::code, EX_SUCCESS, 'exit code is successful';
	is scalar @$Local::Glob::array, scalar @expected, 'there are the expected number of matches'
		or diag( explain $Local::Glob::array );
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @expected ],
		'list as expected';
	};

done_testing();

__END__
