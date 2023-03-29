use strict;
use warnings;

use Test::More 1;

sub compiles_ok {
	my( $command ) = @_;

	my $output = `"$^X" -c $command  2>&1`;
	like $output, qr/syntax OK/, "$command compiles"
		or BAIL_OUT( "$command does not compile" );
	}

sub do_trap (&) {
	my ($stdout, $stderr, $did_exit, $exit_code);

	my $code = shift;

	RUN_CODE: {
		no warnings qw(redefine exiting);
		local *STDOUT;
		local *STDERR;
		open(STDOUT, '>', \$stdout);
		open(STDERR, '>', \$stderr);
		local *CORE::GLOBAL::exit = sub (;$) {
			$did_exit = 1;
			$exit_code = shift;
			};
		$code->();
	}

	return {
		stdout => $stdout,
		stderr => $stderr,
		did_exit => $did_exit,
		exit_code => $exit_code,
		};
	}

1;
