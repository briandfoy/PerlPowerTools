use Test::More 0.94;
use Config;

diag(
	join "\n\t", "Parent \@INC:", @INC, ''
	);

$ENV{PERL5LIB} = join $Config{path_sep}, @INC;
diag( "PERL5LIB: $ENV{PERL5LIB}" );

foreach my $program ( glob( "bin/*" ) ) {
	subtest $program => sub {
		my $output = `$Config{perlpath} -c $program 2>&1`;
		like( $output, qr/syntax OK/, "$program compiles" );
		}
	}

done_testing();
