use strict;
use warnings;

use Test::More;
use Cwd;
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use File::Path qw(make_path);

require './t/lib/common.pl';

my $Program = program_name();

sanity_test($Program);

my $starting_dir = getcwd();
my $program_path = catfile( $starting_dir, $Program );
diag( "Starting working dir is $starting_dir" );
diag( "Program path is $program_path" );

my $test_file = 'a.txt';
my $dir = tempdir( CLEANUP => 1 );
ok( chdir $dir, 'Was able to change into temporary directory' );
diag( "Current working dir is " . getcwd() );

my $subdir = 'child';
make_path $subdir;
ok( -d $subdir, 'Subdirectory is there' );

my $filename = 'a.txt';
open my $fh, '>', $filename;
print {$fh} "a\nb\nc\n";
close $fh;

my $second_filename = 'b.txt';

subtest 'starting files' => sub {
	ok -e $filename, "$filename exists";
	ok ! -e $second_filename, "$second_filename does not exist";
	};

=pod

On Windows, cp a.txt b.txt fails at line 252 with message "cp: can not access B.TXT ... skipping".

=cut

subtest 'same directory' => sub {
	my $rc = system $^X, $program_path, $filename, $second_filename;
	is $rc, 0, 'system exited with 0';
	ok -e $second_filename, "$second_filename exists";
	};

=pod

Overall, this script has problems with case sensitivity, for example cp a.txt dir will create dir/A.TXT.

=cut

subtest 'into directory' => sub {
	my $rc = system $^X, $program_path, $filename, $subdir;
	is $rc, 0, 'system exited with 0';
	ok -e catfile( $subdir, $filename ), "$subdir/$second_filename exists";
	};

done_testing();
