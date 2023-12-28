use File::Spec::Functions;
use IPC::Run3 qw(run3);

use Test::More;

require './t/lib/common.pl';

my $Script = program_name();
diag( "Script is $Script" );
compile_test($Script);
sanity_test($Script);

my $test_file = catfile( qw(t data od ascii.txt ) );

my $outputs = get_outputs();

# print dumper( \$outputs );

my @table = (
	[ [          ], 'no args',  $outputs->{'empty-stdout'}, $outputs->{undef} ],
	[ [$test_file], 'file arg', $outputs->{'plain-stdout'}, $outputs->{undef} ],
	);

foreach my $tuple ( @table ) {
	my( $args, $label, $stdout, $stderr ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, $args, undef );
		diag( "length stdout: " . length($result->{stdout}) );
		diag( "length expected: " . length($stdout) );
		pass();

		is( $result->{stdout}, $stdout  =~ s/\n(?!\z)/ \n/gr, "stdout is as expected for args <@$args>" );
		is( $result->{error},  $stderr, "stderr is as expected for args <@$args>" );
		diag( "AT end" );
		}
	}

done_testing();


sub get_outputs () {
	my %hash;
	$hash{undef} = undef;
	while( <DATA> ) {
		if( /\A%%([a-z-]+)%%/ ) {
			$key = $1;
			$hash{$key} = '';
			}
		else {
			$hash{$key} .= $_;
			}
		}

	return \%hash;
	}

__END__
%%empty%%
%%empty-stdout%%
00000000
%%plain-stdout%%
00000017 000400 001402 002404 003406 004410 005412 006414 007416
00000037 010420 011422 012424 013426 014430 015432 016434 017436
00000057 020440 021442 022444 023446 024450 025452 026454 027456
00000077 030460 031462 032464 033466 034470 035472 036474 037476
00000117 040500 041502 042504 043506 044510 045512 046514 047516
00000137 050520 051522 052524 053526 054530 055532 056534 057536
00000157 060540 061542 062544 063546 064550 065552 066554 067556
00000177 070560 071562 072564 073566 074570 075572 076574 077576
00000217 100600 101602 102604 103606 104610 105612 106614 107616
00000237 110620 111622 112624 113626 114630 115632 116634 117636
00000257 120640 121642 122644 123646 124650 125652 126654 127656
00000277 130660 131662 132664 133666 134670 135672 136674 137676
00000317 140700 141702 142704 143706 144710 145712 146714 147716
00000337 150720 151722 152724 153726 154730 155732 156734 157736
00000357 160740 161742 162744 163746 164750 165752 166754 167756
00000377 170760 171762 172764 173766 174770 175772 176774 177776
00000400
