use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use Test::More;

$|++;

use lib qw(t/lib);
require "common.pl";

# set default path to yes
my $yes_path = catfile '.', program_name();
diag "yespath is originally <$yes_path>";
use Cwd; diag "pwd is " . getcwd();

diag "glob is " . join " ", glob('bin/*');

compile_test($yes_path);
sanity_test($yes_path);

subtest 'test yes' => sub {
    # Amend path to PPT yes, if required, by setting environment
    # variable YESPATH. This may also be used to compare with
    # other yes implementations, e.g. at /usr/bin/yes.
    if (defined($ENV{YESPATH})) {
        $yes_path = $ENV{YESPATH};
        diag "Testing yes at $ENV{YESPATH}";
        }

	my $failures = 0;
    $failures += ! ok -e $yes_path, "<$yes_path> exists";
    $failures += ! ok -f $yes_path, "<$yes_path> is a file";
    $failures += ! ok -x $yes_path, "<$yes_path> is executable";

	SKIP: {
		skip "there was a problem with <$yes_path>", 1 if $failures;
		skip "Don't run fork test on Windows", 1 if $^O eq 'MSWin32';
		subtest 'fork and run yes in child process' => sub {
			run_yes($yes_path);
			run_yes($yes_path, 'iluvperl');
			};
		}
    };

sub run_yes {
    my ($yes_path, $yes_str) = @_;
    my ($pid, $child);
    my $line_count = 10;
    $yes_str = defined $yes_str ? $yes_str : 'y';

    subtest "yes string = <$yes_str>" => sub {
    	open $child, '-|', $^X, $yes_path, $yes_str;

		my $good;
		for (1..$line_count) {
			my $line = <$child>;
			$good += is $line, "$yes_str\n", "line is '$yes_str'.";
			}

		is $good, $line_count, "Expected number of output lines ($line_count).";

		close $child;
		}
    }

done_testing();
