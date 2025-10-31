use strict;
use warnings;

use File::Spec;
use Test::More;

$|++; # autoflush both processes (superfluous?)

subtest 'test yes' => sub {
    # set default path to yes as seen from PPT root directory
    my $yes_path = './bin/yes';
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
            my ($pid, $child);
            if ($pid = open($child, '-|', $yes_path)) {
                # PARENT PROCESS
                # read ten lines from child
                my @lines;
                for (1..10) {
                    # NOTE <> must be called in scalar context to prevent blocking.
                    my $line = <$child>;
                    push @lines, $line;
                }

                is $lines[0], "y\n", 'first line is "y\n"'; # superfluous?
                is scalar(@lines), 10, 'expected no. of output lines (10)';
                my $count_of_ys = grep { /^y$/ } @lines;
                note $count_of_ys;
                is $count_of_ys, 10, 'all 10 lines contain "y\n" only';

                close($child); # apparently superfluous
            } else {
                die "cannot fork:$!\n" unless defined $pid;
                # CHILD PROCESS
                exit; # apparently superfluous
            }
        }
    };
};

done_testing();
