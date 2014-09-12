use Test::More 0.94;


foreach my $program ( glob( "bin/*" ) ) {
	subtest $program => sub {
		my $output = `$^X -cT $program 2>&1`;
		like( $output, qr/syntax OK/, "$program compiles" );
		
		}
	}

done_testing();
