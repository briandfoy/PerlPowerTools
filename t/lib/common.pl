
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);

use Test::More;
use Test::NoWarnings qw(had_no_warnings);

sub compile_test {
	my( $program ) = @_;

	subtest compile => sub {
		return fail( "Program <$program> exists" )
			unless -e $program;
		pass( "Program <$program> exists" );
		my $output = `$^X -c $program 2>&1`;
		like $output, qr/syntax OK/, "$program compiles"
			or diag( $output );
		};
	}

sub end_testing {
	had_no_warnings();
	done_testing();
	}

sub program_name {
	my( $file ) = defined $_[0] ? $_[0] : (caller(0))[1];
	catfile 'bin', basename( dirname( $_[0] ) );
	}

sub sanity_test {
	my( $file ) = (caller(0))[1];
	my $program = program_name($file);

	my $rc = subtest 'sanity_test' => sub {
		compile_test($program);
		};

	unless($rc) {
		done_testing();
		die "No sense continuing after sanity tests fail\n";
		}

	$rc;
	}

1;
