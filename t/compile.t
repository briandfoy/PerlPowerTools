use Test::More 0.94;
use Config;

diag(
	join "\n\t", "Parent \@INC:", @INC, ''
	);

$ENV{PERL5LIB} = join $Config{path_sep}, @INC;
diag( "PERL5LIB: $ENV{PERL5LIB}" ) if $ENV{DEBUG};

# Even programs not in MANIFEST, but they are in the repo and CI
# still catches it
my %SkipPrograms        = map { ( "blib/script/$_" => 1 ) } qw(man);
my %NeedsExternalModule = map { ( "blib/script/$_" => 1 ) } qw(awk make mimedecode);

foreach my $program ( glob( "blib/script/*" ) ) {
	next if exists $SkipPrograms{$program};

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
