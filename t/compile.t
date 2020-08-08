use Test::More 0.94;
use Config;

diag(
	join "\n\t", "Parent \@INC:", @INC, ''
	);

$ENV{PERL5LIB} = join $Config{path_sep}, @INC;
diag( "PERL5LIB: $ENV{PERL5LIB}" ) if $ENV{DEBUG};

my %NeedsExternalModule = map { ( "bin/$_" => 1 ) } qw(awk make mimedecode);

foreach my $program ( glob( "bin/*" ) ) {
	if( $program eq 'bin/man' and exists $ENV{TRAVIS} ) {
		TODO: {
			local $TODO = "Travis Perl can't find DB_File";
			subtest $program => sub {
				my $output = `"$^X" -c $program 2>&1`;
				like( $output, qr/syntax OK/, "$program compiles" );
				};
			}
		next;
		}

	if( exists $NeedsExternalModule{$program} ) {
		TODO: {
			local $TODO = "The program <$program> requires an external module, so fresh environments may fail.";
			subtest $program => sub {
				my $output = `"$^X" -c $program 2>&1`;
				like( $output, qr/syntax OK/, "$program compiles" );
				};
			}
		next;
		}

	subtest $program => sub {
		my $output = `"$^X" -c $program 2>&1`;
		like( $output, qr/syntax OK/, "$program compiles" );
		}
	}

done_testing();
