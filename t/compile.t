use Test::More 0.94;
use Config;

diag(
	join "\n\t", "Parent \@INC:", @INC, ''
	);

$ENV{PERL5LIB} = join $Config{path_sep}, @INC;
diag( "PERL5LIB: $ENV{PERL5LIB}" ) if $ENV{DEBUG};

my @programs = glob( 'blib/script/*' );

my %NeedsExternalModule = map { ( "blib/script/$_" => 1 ) } qw(awk make mimedecode);

foreach my $program ( @programs ) {
	my $command = qq("$^X" -c $program 2>&1);
	my $test = sub {
		my $output = `$command`;
		like( $output, qr/syntax OK/, "$program compiles" );
		};

	if( exists $NeedsExternalModule{$program} ) {
		TODO: {
			local $TODO = "The program <$program> requires an external module, so fresh environments may fail.";
			subtest $program => $test;
			}
		next;
		}

	subtest $program => $test;
	}

done_testing();
