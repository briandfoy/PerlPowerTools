use 5.006;

BEGIN {
	*CORE::GLOBAL::exit = sub { 1 }
	}

use Test::More 0.95;

my $class = 'PerlPowerTools::factor';

subtest setup => sub {
	require_ok( 'bin/factor' );
	can_ok( $class, 'run' );
	};

subtest with_filehandle => sub {
	open my $fh, '>', \ my $string;
	my @numbers = qw( 137 138 );
	$class->run( $fh, @numbers );
	diag( "@numbers:\n$string" );
	like( $string, qr/137: 137/, 'Factors 137 correctly' );
	like( $string, qr/138: 2 3 23/, 'Factors 138 correctly' );
	};

subtest 'factor 899 (RT #98849)' => sub {
	# https://rt.cpan.org/Ticket/Display.html?id=98849
	open my $fh, '>', \ my $string;
	my @numbers = qw( 899 );
	$class->run( $fh, @numbers );
	diag( "@numbers:\n$string" );
	TODO: {
		local $TODO = '899 does not work!';
		like( $string, qr/899: 29 31/, 'Factors 899 correctly' );
		}
	};

done_testing();
