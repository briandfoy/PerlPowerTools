use Test::More 0.94;
use Config;

diag(
	join "\n\t", "Parent \@INC:", @INC, ''
	);

$ENV{PERL5LIB} = join $Config{path_sep}, @INC;
diag( "PERL5LIB: $ENV{PERL5LIB}" );

foreach my $program ( glob( "bin/*" ) ) {
	if ($program eq 'bin/robots') {
		SKIP: {
			eval { require Curses };
			skip "$program requires the Perl Curses module", 1 if $@;
			my $output = `$Config{perlpath} -c $program 2>&1`;
			like( $output, qr/syntax OK/, "$program compiles" );
		};
		next;
	}
	subtest $program => sub {
		my $output = `$Config{perlpath} -c $program 2>&1`;
		like( $output, qr/syntax OK/, "$program compiles" );
		}
	}

done_testing();
