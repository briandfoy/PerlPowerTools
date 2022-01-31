use strict;
use warnings;

use Test::More 0.95 tests => 5;

sub exit_trap (;$) {
	$did_exit = 1;
	$exit_code = shift;
	no warnings 'exiting';
	last RUN_CODE;
}

sub do_trap (&) {
	my ($stdout, $stderr, $did_exit, $exit_code);

	$did_exit = $exit_code = undef;
	$stdout = $stderr = '';
	local *STDOUT;
	local *STDERR;
	open(STDOUT, '>', \$stdout);
	open(STDERR, '>', \$stderr);

	my $code = shift;
	RUN_CODE: {
		$code->();
	}

	return {
		stdout => $stdout,
		stderr => $stderr,
		did_exit => $did_exit,
		exit_code => $exit_code,
		};
}

BEGIN {
	no warnings 'redefine';
	*CORE::GLOBAL::exit = \&exit_trap;
}

1;
