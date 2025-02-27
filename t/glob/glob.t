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

my $class = 'Local::Glob';


my $NO_MATCH_MESSAGE = 'glob: No match.';

subtest setup => sub {
	use lib qw(.);
	require_ok( 'bin/glob' );
	can_ok( $class, 'run' );
	};

subtest 'no args' => sub {
	$class->run();

	is $Local::Glob::code, 2, 'exit code is error';
	is "$Local::Glob::message", '', 'there is no output message';
	};

subtest 'no wildcards' => sub {
	my @args = qw(foo bar);

	$class->run(@args);

	is $Local::Glob::code, 0, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply $Local::Glob::array, [@args], 'list as expected';
	};

subtest 'one arg, some matches' => sub {
	my @args = qw(t/lib/*);

	$class->run(@args);

	is $Local::Glob::code, 0, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[map { "t/lib/$_" } qw(common.pl utils.pm)],
		'list as expected';
	};

subtest 'one arg, no matches' => sub {
	my @args = qw(t/not_there/*);

	$class->run(@args);

	is $Local::Glob::code, 1, 'exit code is no matches';
	is "$Local::Glob::message", $NO_MATCH_MESSAGE, 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[map { "t/lib/$_" } qw(common.pl utils.pm)],
		'list as expected';
	};

subtest 'two arg, some matches' => sub {
	my @args = qw(t/lib/* t/glob/*);

	$class->run(@args);

	is $Local::Glob::code, 0, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ 't/glob/glob.t', map { "t/lib/$_" } qw(common.pl utils.pm)],
		'list as expected';
	};

subtest 'one tidle, no wildcard' => sub {
	my @args = qw(~nouserxyz456);

	$class->run(@args);

	is $Local::Glob::code, 0, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ @args ],
		'list as expected';
	};

subtest 'two tidle, no wildcard' => sub {
	my @args = qw(~nouserxyz456 ~nousersafgadfg);

	$class->run(@args);

	is $Local::Glob::code, 0, 'exit code is successful';
	is "$Local::Glob::message", '', 'there is no output message';
	is_deeply
		[ sort @$Local::Glob::array ],
		[ sort @args ],
		'list as expected';
	};

done_testing();

__END__
