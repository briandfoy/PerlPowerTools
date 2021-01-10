use strict;
use Test::More 1;

my $input_name   = 't/data/uuencoded.uu';
END { unlink $input_name }

my $decoded_text = "Paul is dead\n";
my $output_mode  = '664';

my $encoded_text = <<"HERE";
begin %%MODE%% %%FILE%%
-4&%U;"!I<R!D96%D"@``
`
end
HERE

sub make_input_file {
	my( $filename, $mode ) = @_;
	my $output = $encoded_text;
	$output =~ s/%%FILE%%/$filename/;
	$output =~ s/%%MODE%%/$mode/;

	open my $uu, '>', $input_name;
	print { $uu } $output;
	close $uu;
	}

my( $program ) = grep { -e } map { "$_/uudecode" } qw(bin blib/uudecode);
subtest 'sanity' => sub {
	ok(   -e $program, "program <$program> exists" );
	};

subtest 'decode_to_file' => sub {
	my $output_name = 't/data/decode_to_file.txt';
	my $mode        = '664';

	unlink $input_name;
	ok( ! -e $input_name, "uu file <$input_name> is not there yet (good)" );
	make_input_file( $output_name, $mode );
	ok( -e $input_name, "uu file <$input_name> exists" );

	unlink $output_name;
	ok( ! -e $output_name, "output file <$output_name> does not exist yet" );
	system $^X, $program, $input_name;
	ok(   -e $output_name, "output file <$output_name> now exists" );
	is(
		sprintf( '%o', (stat $output_name)[2] & 0777 ),
		$mode,
		"output file has the right mode"
		);

	my $output = do { local( @ARGV, $/ ) = $output_name; <> };

	is( $output, $decoded_text, "Output in <$output_name> is right" );
	unlink $output_name or diag "Unintentionally leaving behind <$output_name>!";
	};

subtest 'decode_to_stdout' => sub {
	my $output_name = '-';
	my $mode        = '664';

	unlink $input_name;
	ok( ! -e $input_name, "uu file <$input_name> is not there yet (good)" );
	make_input_file( $output_name, $mode );
	ok( -e $input_name, "uu file <$input_name> exists" );

	my $output = `$^X $program $input_name`;

	is( $output, $decoded_text, "standard output is the right message" );
	};

subtest 'decode_to_other_file' => sub {
	my $output_name = 't/data/decode_to_file.txt';
	my $alt_name    = 't/data/alt_uu_out.txt';
	my $mode        = '444';

	unlink $output_name, $alt_name;
	ok( ! -e $output_name, "output file <$output_name> is not there (good)" );
	ok( ! -e $alt_name,    "output file <$alt_name> is not there yet (good)" );

	unlink $input_name;
	ok( ! -e $input_name, "uu file <$input_name> is not there yet (good)" );
	make_input_file( $output_name, $mode );
	ok( -e $input_name, "uu file <$input_name> exists" );

	system $^X, $program, $input_name, $alt_name;
	ok( ! -e $output_name, "output file <$output_name> is not there (good)" );
	ok(   -e $alt_name,    "output file <$alt_name> is now there (good)" );
	is(
		sprintf( '%o', (stat $alt_name)[2] & 0777 ),
		$mode,
		"output file has the right mode"
		);

	my $output = do { local( @ARGV, $/ ) = $alt_name; <> };

	is( $output, $decoded_text, "standard output is the right message" );
	unlink $alt_name or diag "Unintentionally leaving behind <$alt_name>!";

	subtest 'decode_to_alt_stdout' => sub {
		my $output = `$^X $program $input_name -`;
		ok( ! -e $output_name, "output file <$output_name> is not there (good)" );
		is( $output, $decoded_text, "standard output is the right message" );
		};
	};

done_testing();
