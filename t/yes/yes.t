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
            fork_yes($yes_path);
            fork_yes($yes_path, 'iluvperl');
        }
    };
};

sub fork_yes {
    my ($yes_path, $yes_str) = @_;
    my ($pid, $child);
    $yes_str ||= 'y';
    if ($pid = open($child, '-|', "$yes_path $yes_str")) {
        # PARENT PROCESS
        # read ten lines from child
        my @lines;
        for (1..10) {
            # NOTE <> must be called in scalar context to prevent blocking.
            my $line = <$child>;
            push @lines, $line;
        }

        is $lines[0], "$yes_str\n", "First line is '$yes_str'.\n"; # superfluous?
        is scalar(@lines), 10, 'Expected no. of output lines (10).';
        my $count_of_ys = grep { /^$yes_str$/ } @lines;
        note $count_of_ys;
        is $count_of_ys, 10, "All 10 lines contain '$yes_str' only.\n";

        close($child); # apparently superfluous
    } else {
        die "cannot fork:$!\n" unless defined $pid;
        # CHILD PROCESS
        exit; # apparently superfluous
    }
}

done_testing();
