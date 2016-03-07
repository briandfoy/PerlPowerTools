use Test::More 0.95;

use File::Spec;

my $file = File::Spec->catfile( qw(blib script true) );

subtest 'check file' => sub {
	ok( -e $file, "$file exists" );
	SKIP: {
		skip "This test isn't for Windows", 1 if $^O eq 'MSWin32';
		ok( -x $file, "$file is executable" );
		}
	};

subtest 'exit value' => sub {
	my $rc = system( $file );
	is( 0 + $rc, 0, 'true returns a unix true' );
	};

done_testing();
