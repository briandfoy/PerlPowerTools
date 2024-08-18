require './t/lib/common.pl';
my $Script = program_name();

use Test::More;

my @table = (
		{
		label => "-n",
		args  => [qw( -n t/data/cat/cat-n-1.txt )],
		stdout => "     1\tThis is the first line\n",
		},
	);

foreach my $hash ( @table ) {
	subtest $hash->{label} => sub {
		my $result = run_command( $Script, $hash->{args}, undef );
		is $result->{stdout}, $hash->{stdout};
		};
	}

done_testing();
