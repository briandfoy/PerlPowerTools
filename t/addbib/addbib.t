use 5.006;
use strict;

use lib qw(t/lib);
require "common.pl";

use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);
use File::Temp;
use Test::More 0.95;

my $unwritable_file;

BEGIN {
	$unwritable_file = catfile qw(t data unwriteable_file);

	my $message = do {
		if( ! eval "require Term::ReadKey" ) {
			'Term::ReadKey required for testing'
			}
		elsif( $^O eq 'MSWin32' and $ENV{'GITHUB_ACTIONS'} ) {
			q(Can't test on Windows in GitHub Actions);
			}
		else {
			undef;
			}
		};

	if( $message ) {
		plan skip_all => $message;
		done_testing();
		exit;
		}

	if ( $^O eq 'MSWin32' ) {
		system 'attrib',  '+r',  $unwritable_file;  # make read-only
		}
	else {
		chmod 0444, $unwritable_file;
		}
	}

BEGIN {
	*CORE::GLOBAL::exit = sub { defined $_[0] ? $_[0] : 0 }
	}


my $program = 'bin/addbib';
my $class = "PerlPowerTools::" . basename($program);

$main::output = '';
open $main::out_fh, '>', \$main::output;

$main::error = '';
open $main::err_fh, '>', \$main::error;

my $subclass = do {
	package PerlPowerTools::addbib::Test;
	sub output_fh { $main::out_fh }
	sub error_fh  { $main::err_fh }
	our @ISA = ($class);
	__PACKAGE__;
	};

sanity_test($program);

subtest setup => sub {
	use lib qw(.);
	require_ok( $program );
	can_ok( $_, 'run' ) for ( $class, $subclass );
	};

subtest "database" => sub {
	subtest 'no argument' => sub {
		reset_outputs();
		my $rc = $subclass->run();
		is $rc, 2, 'returns 2';
		shows_usage();
		error_empty();
		};

	subtest 'bad path' => sub {
		reset_outputs();
		my $dir = '/does/not/exist';
		ok ! -e $dir, 'directory does not exist (good)';
		my $path = catfile $dir, 'db.txt';

		my $rc = $subclass->run($path);
		is $rc, 1, 'returns 1';
		output_empty();
		like $main::error, qr/Could not open/, 'sees error message';
		};

	subtest 'unwriteable path' => sub {
		reset_outputs();
		ok ! -w $unwritable_file, 'database file is unwritable (good)' or return;
		my $rc = eval { $subclass->run( $unwritable_file ) };
		is $rc, 1, 'returns 1';
		output_empty();
		like $main::error, qr/Could not open/, 'saw error message';
		};

	subtest 'good path' => sub {
		my($fh, $filename) = File::Temp::tempfile();

		my $input = "y\n\003";
		my $args = [
			$filename,
			];
		my $result = run_command(
			$program,
			$args,
			$input
			);

		is $result->{'exit'}, 130, 'saw instructions'; # Cntl-C out = 127 + 3
		};
	};

subtest "promptfile" => sub {
	subtest 'no argument' => sub {
		reset_outputs();
		my $rc = $subclass->run( '-p' );
		is $rc, 2, 'returns 2';
		shows_usage();
		};

	subtest 'bad path' => sub {
		reset_outputs();
		my $dir = '/does/not/exist';
		ok ! -e $dir, 'directory does not exist (good)' or return;
		my $path = catfile $dir, 'db.txt';

		my $rc = $subclass->run( -p $path );
		is $rc, 2, 'returns 2';
		shows_usage();
		error_empty();
		};

	subtest 'unwriteable path' => sub {
		reset_outputs();
		ok ! -w $unwritable_file, 'database file is unwritable (good)' or return;
		my $rc = eval { $subclass->run( $unwritable_file ) };
		is $rc, 1, 'returns 1';
		output_empty();
		like $main::error, qr/Could not open/, 'saw error message';
		};
	};

subtest 'run' => sub {
	subtest 'show instructions' => sub {
		my($fh, $filename) = File::Temp::tempfile();

		my $input = "y\n\003";
		my $args = [
			$filename,
			];
		my $result = run_command(
			$program,
			$args,
			$input
			);

		like $result->{'stdout'}, qr/addbib will prompt you/, 'saw instructions';
		};

	subtest q(don't show instructions) => sub {
		my($fh, $filename) = File::Temp::tempfile();

		my @tuples = (
			[ "\n\003",  'no n'   ],
			[ "n\n\003", 'with n' ],
			);

		foreach my $tuple ( @tuples ) {
			my( $input, $label ) = @$tuple;
			subtest $label => sub {
				my $input = "\n\003";
				my $args = [
					$filename,
					];
				my $result = run_command(
					$program,
					$args,
					$input
					);

				unlike $result->{'stdout'}, qr/addbib will prompt you/, 'did not see instructions (good)';
				};
			}
		}
	};

sub reset_outputs {
	$main::output = '';
	$main::error  = '';
	}

sub shows_usage {
	like $main::output, qr/usage/, 'saw usage message';
	}

sub error_empty {
	like $main::error, qr/\A\z/, 'error is empty';
	}

sub output_empty {
	like $main::output, qr/\A\z/, 'output is empty';
	}

done_testing();
