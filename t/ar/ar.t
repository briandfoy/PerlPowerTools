use 5.006;
use strict;

use Test::More 0.95;
use File::Spec;
use File::Compare;

use lib qw(t/lib);
require "common.pl";

my $program = program_name();

compile_test($program);
sanity_test($program);

my $test_data_dir = File::Spec->catfile( 't',       'data', 'ar' );

# test files
my %tf;
foreach ( qw /
	a b c d out01.a out02.a out03.a out04.a out05.a
	archive_ppt_1.a archive_ppt_2.a
	archive_ppt_long_filename_1.a archive_ppt_long_filename_2.a
	archive_freebsd_long_filename_1.a archive_freebsd_long_filename_2.a
	archive_gnu_long_filename_1.a archive_gnu_long_filename_2.a
	/ ) {
	$tf{$_} = File::Spec->catfile( $test_data_dir, $_ );
	}
$tf{'another/a'} = File::Spec->catfile ($test_data_dir, 'another', 'a');
$tf{'another/b'} = File::Spec->catfile ($test_data_dir, 'another', 'b');

# We use a string to store the command to be tested, with the following format:
# 'archive | opts of the 1st cmd | files of the 1st cmd | opts of the 2nd cmd | files of the 2nd cmd | ...'
# We will use these strings to generate the tests, as well as the scripts used
# to generate the test files.
my @tests_archive = (
	'out01.a | qc | a b c',
	'out02.a | rc | a b c',
	'out03.a | qc | a b c | r | another/a',
	'out04.a| qc | a b c | d | a',
	'out05.a| qc |a b c another/a',
    );

# Generate gen_out_a.sh, which is used to generate the test files.
open my $fh, '>', File::Spec->catfile( 't', 'data', 'ar', 'gen_out_a.sh');
print $fh '#!/bin/sh', "\n";
print $fh 'rm -rf out*.a', "\n\n";
foreach (@tests_archive) {
	my @fileds = map { s/^\s+|\s+$//g; $_ } split /\|/;
	my $archive = shift @fileds;
	while ( @fileds ) {
		my $opts = shift @fileds;
		my $files = shift @fileds;
		print $fh "ar $opts $archive $files\n";
		}
	print $fh "\n";
	}

close $fh;

foreach ( @tests_archive ) {
	my $label = $_;
	my @fileds = map { s/^\s+|\s+$//g; $_ } split /\|/;
	my $archive = $tf{shift @fileds};
	#  Do not create the archive file in advance.
	#  Otherwise ar treats it as an existing non-archive file and fails.
	my ( undef, $archive_by_ppt ) = File::Temp::tempfile( OPEN => 0);
	subtest $label => sub {
		while ( @fileds ) {
			my @opts = split /\s+/, shift @fileds;
			my @files = map { $tf{$_} } split /\s+/, shift @fileds;
			my $result = run_command( $program, [ @opts, $archive_by_ppt, @files ], undef );
			is $result->{'exit'}, 0, 'exited successfully';
			}
		TODO: { local $TODO = 'not working yet'; is compare( $archive_by_ppt, $archive ), 0, 'execution succeeded'; }
		};
    }

my @tests_list = (
	'archive_ppt_1.a', ['a', 'b', 'c', ''],
	# TODO 'archive_ppt_2.a', ['a', 'b', 'c', 'a', ''],
	'archive_ppt_long_filename_1.a', ['a_looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_name_file', ''],
	'archive_ppt_long_filename_2.a', ['a_looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_name_file',
						'file_with_a_looooooooooooooooooooooooooooooooooooooooooooooooooong_name', ''],
	'archive_freebsd_long_filename_1.a', ['a', 'file_with_a_looooooooooooooooooooooooooooooooooooooooooooooooooong_name', ''],
	'archive_freebsd_long_filename_2.a', ['a', 'file_with_a_looooooooooooooooooooooooooooooooooooooooooooooooooong_name',
						'a_looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_name_file',
						''],
	'archive_gnu_long_filename_1.a', ['a_looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_name_file', ''],
	'archive_ppt_long_filename_2.a', ['a_looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong_name_file',
						'file_with_a_looooooooooooooooooooooooooooooooooooooooooooooooooong_name',
						''],
    );

while ( @tests_list ) {
	my $label = shift @tests_list;
	my $archive = $tf{$label};
	my $output = join "\n", @{shift @tests_list};
	subtest "list $label" => sub {
		my $result = run_command ( $program, [ 't', $archive ], undef );
		# Temporary code: use the dumper for debugging.
		use Data::Dumper;
		print $label, Dumper($result);
		is $result->{'exit'}, 0, 'exited successfully';
		is $result->{'stdout'}, $output, 'execution succeeded';
		};
}

done_testing();
