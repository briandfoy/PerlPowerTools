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

my $a_f = File::Spec->catfile( 't' , 'data', 'ar', 'a');
my $b_f = File::Spec->catfile( 't' , 'data', 'ar', 'b');
my $c_f = File::Spec->catfile( 't' , 'data', 'ar', 'c');
my $d_f = File::Spec->catfile( 't' , 'data', 'ar', 'd');

my $out01_f = File::Spec->catfile( 't' , 'data', 'ar', 'out01.a');
my $out02_f = File::Spec->catfile( 't' , 'data', 'ar', 'out02.a');

my $another_a_f = File::Spec->catfile( 't' , 'data', 'ar', 'another_a', 'a');
my $another_b_f = File::Spec->catfile( 't' , 'data', 'ar', 'another_b', 'b');

subtest 'ar q out01.a a b c' => sub {
	my ( $fh, $filename ) = File::Temp::tempfile();
	my $result = run_command( $program, [ 'q', $filename, $a_f, $b_f, $c_f ], undef );
	is $result->{'exit'},              0, 'exited successfully';
	TODO: { local $TODO = 'not working yet'; is compare( $filename, $out01_f ), 0, 'execution succeeded'; }
	};


done_testing();
