use 5.006;
use strict;

use Test::More 0.95;

require './t/lib/common.pl';
my $Script = program_name();

compile_test($Script);
sanity_test($Script);

use Test::More 1;

subtest "optional number" => sub {
	subtest "who" => sub {
		my $argv  = [ '-d', '-0', 'who', 1, 2, 3, 4, 5 ];
		my @executed = ( 
			'exec who', 
			'exec who', 
			'exec who', 
			'exec who', 
			'exec who', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "cmp" => sub {
		my $argv  = [ '-d', '-2', 'cmp', 'a1', 'b1', 'a2', 'b2', 'a3', 'b3' ];
		my @executed = ( 
			'exec cmp a1 b1', 
			'exec cmp a2 b2', 
			'exec cmp a3 b3', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "seq" => sub {
		my $argv  = [ '-d', '-3', 'seq', 'a1', 'b1', 'c1', 'a2', 'b2', 'c2' ];
		my @executed = ( 
			'exec seq a1 b1 c1', 
			'exec seq a2 b2 c2', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	};


subtest "magic character" => sub {
	subtest "ls" => sub {
		my $argv  = [ '-d', 'ls -al %1', '/usr', '/etc', '/dev' ];
		my @executed = ( 
			'exec ls -al /usr', 
			'exec ls -al /etc', 
			'exec ls -al /dev', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "seq" => sub {
		my $argv  = [ '-d', 'seq %1 %3', 1, 2, 3, 4, 5, 6 ];
		my @executed = ( 
			'exec seq 1 3', 
			'exec seq 4 6', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "changed magic character" => sub {
		my $argv  = [ '-d', '-aF', 'seq F1 F3', 1, 2, 3, 4, 5, 6 ];
		my @executed = ( 
			'exec seq 1 3', 
			'exec seq 4 6', 
		);
		my $expect = join( "\n", ( @executed, '' ) );
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	};


subtest "fixed arguments" => sub {
	subtest "ls" => sub {
		my $argv  = [ '-d', '-f', 1, 'ls', '-al', '/usr', '/etc', '/dev' ];
		my @executed = (
			'exec ls -al /usr',
			'exec ls -al /etc',
			'exec ls -al /dev',
		);
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "seq" => sub {
		my $argv  = [ '-d', '-f', 2, 'seq', 1, 2, 3, 4, 5, 6 ];
		my @executed = (
			'exec seq 1 2 3',
			'exec seq 1 2 4',
			'exec seq 1 2 5',
			'exec seq 1 2 6',
		);
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	subtest "cmp" => sub {
		my $argv  = [ '-d', '-f', 1, 'cmp', 1, 2, 3, 4, 5, 6 ];
		my @executed = (
			'exec cmp 1 2',
			'exec cmp 1 3',
			'exec cmp 1 4',
			'exec cmp 1 5',
			'exec cmp 1 6',
		);
		my $result = run_command( $Script, $argv, undef );
		is( $result->{stdout}, join( "\n", @executed, '' ) );
		};
	};

done_testing();
