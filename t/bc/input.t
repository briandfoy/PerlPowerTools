#!/usr/bin/perl

# bc.t - test for script bc

# Author:  Gary Puckering, gary.puckering@outlook.com
# Date written:  2023-06-16

# Test cases based on the GNU bc documentation
# See https://www.gnu.org/software/bc/manual/text/bc.txt

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;

require './t/lib/common.pl';

# we expect to run this from the PerlPowerTools directory
my $Script = program_name();

run_tests();

sub run_tests {
	sanity_test($Script);

    my @tables = (
        operator_table(),
        precedence_table(),
        special_expr_table(),
        statement_table(),
    	);

	run_table($_) foreach @tables;

    return;
	}

done_testing();

sub operator_table {
    my $table = [
        'operators',
        [ '-1',           '-1',      'negation' ],
        [ 'var=12',       '12',      'variable assignment' ],
        [ 'v=3; ++v',     "3\n4",    'prefix increment' ],
        [ 'v=3; --v',     "3\n2",    'prefix increment' ],
        [ 'v=3; v++; v',  "3\n3\n4", 'postfix increment' ],
        [ 'v=3; v--; v',  "3\n3\n2", 'postfix increment' ],
        [ 'v=3; v+=5; v', "3\n8\n8", 'postfix increment' ],
        [ 'v=5; v-=3; v', "5\n2\n2", 'postfix decrement' ],
        [ '1+2',          '3',       'addition' ],
        [ '5-3',          '2',       'subtraction' ],
        [ '3*5',          '15',      'multiplication' ],
        [ '15/3',         '5',       'division' ],
        [ '15%3',         '0',       'remainder zero' ],
        [ '29%5',         '4',       'remainder four' ],
        [ '2^15',         '32768',   'exponentiation' ],
        [ '3*2+5',        '11',      'expr without parens' ],
        [ '3*(2+5)',      '21',      'expr with parens' ],
        [ 'sqrt(16)',     '4',       'sqrt' ],
        [ '!0',           '1',       'boolean not' ],
        [ '!1',           '0',       'boolean not' ],
        [ '1 && 1',       '1',       'boolean and' ],
        [ '1 && 0',       '0',       'boolean and' ],
        [ '0 && 1',       '0',       'boolean and' ],
        [ '0 && 0',       '0',       'boolean and' ],
        [ '1 || 1',       '1',       'boolean or' ],
        [ '1 || 0',       '1',       'boolean or' ],
        [ '0 || 1',       '1',       'boolean or' ],
        [ '0 || 0',       '0',       'boolean or' ],
        [ '9 == 9',       '1',       'equals (true)' ],
        [ '9 == 8',       '0',       'equals (false)' ],
        [ '9 != 8',       '1',       'not equals (true)' ],
        [ '9 != 9',       '0',       'not equals (false)' ],
        [ '5 < 7',        '1',       'less than' ],
        [ '5 <= 5',       '1',       'less than or equal' ],
        [ '7 > 5',        '1',       'greater than' ],
        [ '7 >= 7',       '1',       'greater than or equal' ],
        [ '7 >= 7',       '1',       'greater than or equal' ],
        [
        	"x = 3\nx *= 4",
        	"3\n12",
        	'binary assignment (multiplication)'
        ],
        [
        	"x = 16\nx /= 4",
        	"16\n4",
        	'binary assignment (division)'
        ],
        [
        	"x = 16\nx /= 0.5",
        	"16\n32",
        	'binary assignment (division by fraction)',
        ],
        [
        	"x = 16\nx /= 0",
        	"16",
        	'binary assignment (division)',
        	'Runtime error (func=(main), adr=4): Divide by zero'
        ],
        [
        	"x = 56\nx %= 17",
        	"56\n5",
        	'binary assignment (modulo)'
        ],
        [
        	"x = 56\nx %= 0.5",
        	"56",
        	'binary assignment (modulo fraction 0.5)',
        	'Runtime error (func=(main), adr=4): Modulo by zero',
        ],
        [
        	"x = 56\nx %= 1.9",
        	"56",
        	'binary assignment (modulo fraction 1.9)',
        	'Runtime error (func=(main), adr=4): Modulo by zero',
        	'Need to investigate fractional modulo'
        ],
		[
        	"x = 56\nx %= 0",
        	"56",
        	'binary assignment (modulo zero)',
        	'Runtime error (func=(main), adr=4): Modulo by zero',
        ],
		[
        	"x = 56\nx %= -2",
        	"56",
        	'binary assignment (modulo negative number)',
        	'Runtime error (func=(main), adr=4): Modulo by zero',
        	'todo'
        ],
		[
        	"x = 5\nx ^= 4",
        	"5\n625",
        	'binary assignment (exponentiation)'
        ],
        [
        	"x = 5\nx ^= 0",
        	"5\n1",
        	'binary assignment (exponentiation - 0 power)'
        ],
        [
        	"x = 5\nx ^= -1",
        	"5\n0.2",
        	'binary assignment (exponentiation - negative power)'
        ],
        [
        	"x = 5\nx ^= 0.5",
        	qr/5\n2\.23606/,
        	'binary assignment (exponentiation - fractional power)'
        ],
        [
        	"x = 5\ny = 2\nx ^= y",
        	"5\n2\n25",
        	'binary assignment (exponentiation - two variables)'
        ],
        [
        	"x = -1\ny = 0.5\nx ^= y",
        	qr/\A-1\n0.5\n-?NaN$/i, # NaN might be -nan
        	'binary assignment (exponentiation - square root of -1)'
        ],
    ];
	}

sub precedence_table {
    my $table = [
        'precedence',
        [ 'v = (3 < 5)',  '1',       'just like gnu bc' ],

        # according to the GNU bc documentation, their implementation
        # will assign 3 to v and then do the relational test
        [ 'v = 3 < 5',    '1',       ' not like gnu bc' ],

        [ 'v = 4+5*2^3',  '44',      'PEDMAS' ],
        [ 'v = (4+5)*2',  '18',      'PEDMAS' ],
        [ 'v = -(4+5)+8', '-1',      'PEDMAS' ],
    ];
	}

sub special_expr_table {
	# 1.41421 35623 73095 04880 16887 24209 7 USE_QUADMATH
	# 1.41421 35623 73095 04                  USE_LONG_DOUBLE
	# 1.41421 35623 731                       -

	my $perl_sqrt_2 = sqrt(2);
	diag( "Perl sqrt(2) is <$perl_sqrt_2>" );

    my $table = [
        'special expressions',
        [ 'sqrt(2)',          $perl_sqrt_2,             'sqrt(2) returns appropriate value'      ],
        [ 'length(sqrt(2))',  length($perl_sqrt_2) - 1, 'length(sqrt(2)) has the expected value' ],
        [ 'scale(sqrt(2))',   length($perl_sqrt_2) - 2, 'precision digits' ],
    ];
	}

sub statement_table {
    ## no critic [ValuesAndExpressions::RequireInterpolationOfMetachars]
    my $table = [
        'statements',
        [
        	q("a string"),
            'a string',
            'string literal',
        ],

        [
            # need to print the newline here so that the test harness
            # recognizes the end of the test output
            'print "1+2", " is ", 1+2, "\n"',
            '1+2 is 3',
            'print statement',
        ],

        [
        	'{ print "a"; print "b"; print "\n" }',
            'ab',
            'compound statement',
        ],

        [
        	'v=5; while (v--) { print v }; print "\n"',
            "5\n43210",
            'while statement',
        ],

        [
        	'for (v=0;v<5;v++) { print v }; print "\n"',
            "01234",
            'for statement',
        ],

        [
        	'for ( v=0; v<5; v++) { print v; if (v>2) break }; print "\n"',
            "01230\n",
            'for with break statement',
        ],

        # The following aren't being tested because they are extensions
        # that aren't support in the PerlPowerTools implementation of bc
        # - read()
        # - if ... else
        # - continue
        # - halt
        # - warranty
        # - define (because I can't even get it to work interactively)

        # Not testing this, for obvious reasons
        # - quit
    ];
}

sub run_table {
    my( $table ) = @_;

    my $label = shift @$table;

    subtest $label => sub {
        foreach my $tuple (@$table) {
            my( $input, $expected, $description, $error, $todo ) = @$tuple;
            $expected .= "\n" unless ref $expected;

            my ( $fh, $temp_filename ) = tempfile();
			print {$fh} $input, "\n";

			my $output = `"$^X" $Script $temp_filename`;

			TODO: {
				local $TODO = $todo;
				if( ! ref $expected ) {
					is $output, $expected, $description;
					}
				elsif( ref $expected eq ref qr// ) {
					like $output, $expected, $description;
					}
				}
            }
        };

    return;
	}
