use strict;
use warnings;

use Test::More;
END { done_testing() }

use lib qw(t/lib);
use utils;

use File::Basename;
use File::Spec::Functions;
use IPC::Run3 qw(run3);

my $command = 'bin/rev';
my $basename = basename($command);

subtest script => sub {
	ok( -e $command, "$command exists" );
	compiles_ok( $command );
	};

subtest "from file" => sub {
	my $file = catfile( qw(t data rev reverse-this.txt) );
	ok( -e $file, "Test file <$file> exists" );
	ok( -r $file, "Test file <$file> is readable" );

	my $expected = join '',
		map { chomp; reverse($_) . "\n" }
		do { local @ARGV = $file; <> };

 	my( $input, $output, $error );
 	my @command = ( $^X, $command, $file );
  	run3 \@command, \$input, \$output, \$error;

	is $output, $expected, "output has the lines reversed";
	};

subtest "from stdin" => sub {
 	my( $output, $error );
 	my $input = "cat\ndog\nbird\n";
	my $expected = "tac\ngod\ndrib\n";

 	my @command = ( $^X, $command );
  	run3 \@command, \$input, \$output, \$error;

	is $output, $expected, "output has the lines reversed";
	};

subtest "version" => sub {
 	my( $output, $error );

 	my @command = ( $^X, $command, '--version' );
  	run3 \@command, undef, \$output, \$error;

	like $output, qr/\Q$basename\E \d+\.\d+/, "shows version message";
	};

subtest "help" => sub {

	foreach my $arg ( '-h', '--help' ) {
	 	my( $output, $error );
 		my @command = ( $^X, $command, $arg );
  		run3 \@command, undef, \$output, \$error;
		like $output, qr/Usage: \Q$basename/, "shows help message";
		}
	};
