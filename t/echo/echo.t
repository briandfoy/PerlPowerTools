use strict;
use warnings;

use Test::More 1;
require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

my ($stdout, $stderr, $did_exit, $exit_code);

my $class = 'PerlPowerTools::echo';

subtest no_input => sub {
	my $result = run_command( $Script, [], undef );
	is( $result->{exit}, 0 );
	is( $result->{stdout}, "\n" );
	is( $result->{stderr}, '' );
};

subtest ask_for_help => sub {
	my $stdout = <<'HELP';
Usage: echo [-n] [arguments]

Displays the command line arguments, seperated by spaces.

Options:
       -n:     Do not print a newline after the arguments.
       -?:     Display usage information.
HELP
	my $result = run_command( $Script, [qw(-?)], undef );
	is( $result->{exit}, 0 );
	is( $result->{stdout}, $stdout );
	is( $result->{stderr}, '' );
};

subtest no_new_lines => sub {
	my $stdout = 'no new lines';
	my $result = run_command( $Script, ['-n', 'no new lines'], undef );
	is( $result->{exit}, 0 );
	is( $result->{stdout}, $stdout );
	is( $result->{stderr}, '' );
};

subtest with_new_lines => sub {
	my $stdout = 'with new lines';
	my $result = run_command( $Script, [$stdout], undef );
	is( $result->{exit}, 0 );
	is( $result->{stdout}, $stdout . "\n" );
	is( $result->{stderr}, '' );
};

done_testing();

__END__
