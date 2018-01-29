use strict;
use warnings;

use Test::More 0.95;

my ($stdout, $stderr, $did_exit, $exit_code);
sub exit_trap (;$) {
	$did_exit = 1;
	$exit_code = shift;
	no warnings 'exiting';
	last RUN_CODE;
}

sub do_trap (&) {
	$did_exit = $exit_code = undef;
	$stdout = $stderr = '';
	close(STDOUT);
	close(STDERR);
	open(STDOUT, '>', \$stdout);
	open(STDERR, '>', \$stderr);

	my $code = shift;
	RUN_CODE: {
		$code->();
	}
}

BEGIN {
	no warnings 'redefine';
	*CORE::GLOBAL::exit = \&exit_trap;
}

my $class = 'PerlPowerTools::echo';

subtest setup => sub {
	require_ok( 'bin/echo' );
	can_ok( $class, 'run' );
};

subtest no_input => sub {
	do_trap { $class->run() };
	is ( $did_exit, 1 );
	is ( $exit_code, 0 );
	is ( $stdout, '' );
	is ( $stderr, '' );
};

subtest ask_for_help => sub {
	my $help = <<'HELP';
Usage: echo [-n] [arguments]

Displays the command line arguments, seperated by spaces.

Options:
       -n:     Do not print a newline after the arguments.
       -?:     Display usage information.
HELP
	do_trap { $class->run( '-?' ) };
	is ( $did_exit, 1 );
	is ( $exit_code, 0);
	is ( $stdout, $help );
	is ( $stderr, '' );
};

subtest no_new_lines => sub {
	do_trap { $class->run( '-n', 'no new lines' ) };
	is ( $did_exit, 1);
	is ( $exit_code, 0);
	is ( $stdout, 'no new lines' );
	is ( $stderr, '' );
};

subtest with_new_lines => sub {
	do_trap { $class->run( 'with new lines' ) };
	is ( $did_exit, 1 );
	is ( $exit_code, 0);
	is ( $stdout, "with new lines\n" );
	is ( $stderr, '' );
};

done_testing();

__END__
