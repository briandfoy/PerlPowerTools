use strict;
use warnings;

use Test::More;
use File::Temp qw/ tempdir /;
use File::Path qw/ make_path /;

my $find = "$^X bin/find";

my $dir = tempdir('ppt-find-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

ok(-d $dir, "Created temp dir: $dir");

my @files = map "$dir/$_", qw[
   a/b/c/20.txt
   d/40.txt
   e/f/60.txt
   g/h/i/80.txt
];

my $middle = 50;
my @found;

for my $file (@files) {
    my $path = $file;
    $path =~ s!/[^/]+$!!;

    make_path($path);
    ok(-d $path, "Created path: $path");

    my $fh;
    open $fh, '>', $file and close $fh;
    ok(-e $file, "Created file: $file");

    my $minutes = $file =~ /(\d+)\.txt$/ && $1;
    $found[$minutes > $middle ? 1 : 0] .= "$file\n";

    my $time = time - 60 * $minutes;
    ok(utime($time, $time, $file), "Set file time to $minutes minutes ago");
}

my ($args, $got);

$args = "$dir -type f -amin -50";
$got = join '', sort `$find $args`;
is($got, $found[0], "Found files with -amin: find $args");

$args = "$dir -type f -mmin +50";
$got = join '', sort `$find $args`;
is($got, $found[1], "Found files with -mmin: find $args");

done_testing();

__END__
