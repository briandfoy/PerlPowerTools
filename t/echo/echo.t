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
	is( $result->{exit}, 0, 'exit value is zero');
	is( $result->{stdout}, "\n", 'stdout is empty' );
	is( $result->{stderr}, '', 'stderr is empty' );
};

subtest ask_for_help => sub {
	my $stdout = '-?';
	my $result = run_command( $Script, [$stdout], undef );
	is( $result->{exit}, 0, 'exit value is zero' );
	is( $result->{stdout}, $stdout . "\n", 'stdout is as expected' );
	is( $result->{stderr}, '', 'stderr is empty' );
};

subtest no_new_lines => sub {
	my $stdout = 'no new lines';
	my $result = run_command( $Script, ['-n', $stdout], undef );
	is( $result->{exit}, 0, 'exit value is zero'  );
	is( $result->{stdout}, $stdout, 'stdout is as expected' );
	is( $result->{stderr}, '', 'stderr is empty' );
};

subtest with_new_lines => sub {
	my $stdout = 'with new lines';
	my $result = run_command( $Script, [$stdout], undef );
	is( $result->{exit}, 0, 'exit value is zero'  );
	is( $result->{stdout}, $stdout . "\n", 'stdout is as expected' );
	is( $result->{stderr}, '', 'stderr is empty' );
};

done_testing();

__END__
