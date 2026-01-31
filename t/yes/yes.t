use strict;
use warnings;

use File::Spec;
use Test::More;

$|++;

use lib qw(t/lib);
require "common.pl";

# set default path to yes
my $yes_path = program_name();

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

    ok -e $yes_path && -f $yes_path, "found 'yes' program at $yes_path"
        or return; # fail rest of script

    subtest 'fork and run yes in child process' => sub {
        SKIP: {
            skip "Don't run fork test on Windows", 1 if $^O eq 'MSWin32';
            fork_yes($yes_path);
            fork_yes($yes_path, 'iluvperl');
            }
        };
    };

sub fork_yes {
    my ($yes_path, $yes_str) = @_;
    my ($pid, $child);
    my $line_count = 10;
    $yes_str = defined $yes_str ? $yes_str : 'y';

    subtest "yes string = <$yes_str>" => sub {
		if ($pid = open($child, '-|', "$^X $yes_path $yes_str")) { # PARENT PROCESS
			my @lines;
			for (1..$line_count) {
				# NOTE <> must be called in scalar context to prevent blocking.
				my $line = <$child>;
				push @lines, $line;
				}

			is $lines[0], "$yes_str\n", "First line is '$yes_str'.";
			is scalar(@lines), $line_count, "Expected no. of output lines ($line_count).";

			my $count_of_ys = grep { /^$yes_str$/ } @lines;
			is $count_of_ys, $line_count, "All $line_count lines contain '$yes_str' only.";

			close $child;
			}
		else { # CHILD PROCESS
			die "cannot fork:$!\n" unless defined $pid;
			}
		}
    }

done_testing();
