use Test::More 0.95;

use File::Spec;

my $file;
if ($^O eq 'MSWin32') {
        $file = File::Spec->catfile( qw(blib script false.bat) );
} else {
        $file = File::Spec->catfile( qw(blib script false) );
}

subtest 'check file' => sub {
	ok( -e $file, "$file exists" );
	SKIP: {
		skip "This test isn't for Windows", 1 if $^O eq 'MSWin32';
		ok( -x $file, "$file is executable" );
		}
	};

subtest 'exit value' => sub {
	my $rc = system( $file );
	is( !! $rc, 1, 'false returns a unix false' );
	};

done_testing();
