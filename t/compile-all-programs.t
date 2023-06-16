use Test::More 1;

use File::Basename;
use File::Spec::Functions;

my @programs =
	map { basename($_) }
	grep { ! /\.bat\z/ }
	glob( 'blib/script/*' );

my @expected_test_files =
	map { basename($_) }
	glob( catfile( qw(util test_templates *.t) ) );

foreach my $program ( @programs ) {
	test_dir($program);
	}

done_testing();

sub test_dir {
	my( $program ) = @_;
	ok -d catfile( 't', $program ), "t/$program is a directory";

	foreach my $t_file ( @expected_test_files ) {
		ok -e catfile( 't', $program, $t_file ), "Found test file $t_file";
		}
	}

