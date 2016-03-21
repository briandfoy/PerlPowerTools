use strict;
use warnings;

#BEGIN {
#	*CORE::GLOBAL::exit = sub { 1 }
#	}

use Test::More 0.95;
use Test::Trap v0.3.2;

my $class = 'PerlPowerTools::echo';

subtest setup => sub {
	require_ok( 'bin/echo' );
	can_ok( $class, 'run' );
};

subtest no_input => sub {
	my @r = trap { $class->run() };
    $trap->did_exit;
    is ( $trap->exit, 0);
    $trap->quiet;
};

subtest ask_for_help => sub {
    my @r = trap { $class->run( '-?' ) };
    $trap->did_exit;
    is ( $trap->exit, 0);

    my $help = <<'HELP';
Usage: echo [-n] [arguments]

Displays the command line arguments, seperated by spaces.

Options:
       -n:     Do not print a newline after the arguments.
       -?:     Display usage information.
HELP
    is ( $trap->stdout, $help );

    is ( $trap->stderr, '' );
};

subtest no_new_lines => sub {
    my @r = trap { $class->run( '-n', 'no new lines' ) };
    $trap->did_exit;
    is ( $trap->exit, 0);
    is ( $trap->stdout, 'no new lines' );
    is ( $trap->stderr, '' );
};

subtest with_new_lines => sub {
    my @r = trap { $class->run( 'with new lines' ) };
    $trap->did_exit;
    is ( $trap->exit, 0);
    is ( $trap->stdout, "with new lines\n" );
    is ( $trap->stderr, '' );
};

done_testing();

__END__
