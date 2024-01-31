use File::Spec::Functions;
use IPC::Run3 qw(run3);

use Test::More;

require './t/lib/common.pl';

my $Script = program_name();

compile_test($Script);
sanity_test($Script);

my $test_file = catfile( qw(t data od ascii.txt ) );

my $outputs = get_outputs();

# od adds an extra space at the end of each line
$outputs->{$_} =~ s/\n(?!\z)/ \n/g for qw( plain-stdout plain-x-stdout plain-xj16-stdout plain-xN16-stdout );

my @table = (
	[ [                         ], 'no args',                  $outputs->{'empty-stdout'},      $outputs->{undef} ],
	[ [               $test_file], 'file arg',                 $outputs->{'plain-stdout'},      $outputs->{undef} ],
	[ [ qw(),         $test_file], 'file arg',                 $outputs->{'plain-stdout'},      $outputs->{undef} ],
	[ [ qw(-x),       $test_file], 'file arg (-x)',            $outputs->{'plain-x-stdout'},    $outputs->{undef} ],
	[ [ qw(-x -j 16), $test_file], 'file arg with skip (-x)',  $outputs->{'plain-xj16-stdout'}, $outputs->{undef} ],
	[ [ qw(-x -N 16), $test_file], 'file arg with limit (-x)', $outputs->{'plain-xN16-stdout'}, $outputs->{undef} ],
	);

foreach my $tuple ( @table ) {
	my( $args, $label, $stdout, $stderr ) = @$tuple;

	subtest $label => sub {
		my $result = run_command( $Script, $args, undef );
		is( length($stdout), length($result->{stdout}), "received and expected data lengths are the same" );
		is( $result->{stdout}, $stdout, "stdout is as expected for args <@$args>" );
		is( $result->{error},  $stderr, "stderr is as expected for args <@$args>" );
		}
	}

done_testing();

sub get_outputs () {
	my %hash;
	$hash{undef} = undef;
	while( <DATA> ) {
		if( /\A%%([a-z0-9-]+)%%/i ) {
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
00000000 000400 001402 002404 003406 004410 005412 006414 007416
00000020 010420 011422 012424 013426 014430 015432 016434 017436
00000040 020440 021442 022444 023446 024450 025452 026454 027456
00000060 030460 031462 032464 033466 034470 035472 036474 037476
00000100 040500 041502 042504 043506 044510 045512 046514 047516
00000120 050520 051522 052524 053526 054530 055532 056534 057536
00000140 060540 061542 062544 063546 064550 065552 066554 067556
00000160 070560 071562 072564 073566 074570 075572 076574 077576
00000200 100600 101602 102604 103606 104610 105612 106614 107616
00000220 110620 111622 112624 113626 114630 115632 116634 117636
00000240 120640 121642 122644 123646 124650 125652 126654 127656
00000260 130660 131662 132664 133666 134670 135672 136674 137676
00000300 140700 141702 142704 143706 144710 145712 146714 147716
00000320 150720 151722 152724 153726 154730 155732 156734 157736
00000340 160740 161742 162744 163746 164750 165752 166754 167756
00000360 170760 171762 172764 173766 174770 175772 176774 177776
00000400
%%plain-x-stdout%%
00000000 0100 0302 0504 0706 0908 0b0a 0d0c 0f0e
00000020 1110 1312 1514 1716 1918 1b1a 1d1c 1f1e
00000040 2120 2322 2524 2726 2928 2b2a 2d2c 2f2e
00000060 3130 3332 3534 3736 3938 3b3a 3d3c 3f3e
00000100 4140 4342 4544 4746 4948 4b4a 4d4c 4f4e
00000120 5150 5352 5554 5756 5958 5b5a 5d5c 5f5e
00000140 6160 6362 6564 6766 6968 6b6a 6d6c 6f6e
00000160 7170 7372 7574 7776 7978 7b7a 7d7c 7f7e
00000200 8180 8382 8584 8786 8988 8b8a 8d8c 8f8e
00000220 9190 9392 9594 9796 9998 9b9a 9d9c 9f9e
00000240 a1a0 a3a2 a5a4 a7a6 a9a8 abaa adac afae
00000260 b1b0 b3b2 b5b4 b7b6 b9b8 bbba bdbc bfbe
00000300 c1c0 c3c2 c5c4 c7c6 c9c8 cbca cdcc cfce
00000320 d1d0 d3d2 d5d4 d7d6 d9d8 dbda dddc dfde
00000340 e1e0 e3e2 e5e4 e7e6 e9e8 ebea edec efee
00000360 f1f0 f3f2 f5f4 f7f6 f9f8 fbfa fdfc fffe
00000400
%%plain-xj16-stdout%%
00000020 1110 1312 1514 1716 1918 1b1a 1d1c 1f1e
00000040 2120 2322 2524 2726 2928 2b2a 2d2c 2f2e
00000060 3130 3332 3534 3736 3938 3b3a 3d3c 3f3e
00000100 4140 4342 4544 4746 4948 4b4a 4d4c 4f4e
00000120 5150 5352 5554 5756 5958 5b5a 5d5c 5f5e
00000140 6160 6362 6564 6766 6968 6b6a 6d6c 6f6e
00000160 7170 7372 7574 7776 7978 7b7a 7d7c 7f7e
00000200 8180 8382 8584 8786 8988 8b8a 8d8c 8f8e
00000220 9190 9392 9594 9796 9998 9b9a 9d9c 9f9e
00000240 a1a0 a3a2 a5a4 a7a6 a9a8 abaa adac afae
00000260 b1b0 b3b2 b5b4 b7b6 b9b8 bbba bdbc bfbe
00000300 c1c0 c3c2 c5c4 c7c6 c9c8 cbca cdcc cfce
00000320 d1d0 d3d2 d5d4 d7d6 d9d8 dbda dddc dfde
00000340 e1e0 e3e2 e5e4 e7e6 e9e8 ebea edec efee
00000360 f1f0 f3f2 f5f4 f7f6 f9f8 fbfa fdfc fffe
00000400
%%plain-xN16-stdout%%
00000000 0100 0302 0504 0706 0908 0b0a 0d0c 0f0e
00000020
