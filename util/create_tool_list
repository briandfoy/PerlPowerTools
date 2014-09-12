use v5.10;

my @files = glob( "bin/*" );

foreach my $file ( @files ) {
	my $data = do { local( @ARGV, $/ ) = $file; <> };
	
	my( $name ) = $data =~ m/
		=head1 \s+ NAME \s+ (.*?) \v
		/xi;

	$name //= $file;

	say "=item $name\n";
	}
