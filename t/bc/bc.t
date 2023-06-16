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

# we expect to run this from the PerlPowerTools directory
my $Script = './bin/bc';

run_tests();

sub run_tests
{
	subtest sanity => sub {
		ok -e $Script, "$Script exists";
	};

    my @tables = (
        operator_table(),
        precedence_table(),
        special_expr_table(),
        statement_table(),
    );

    foreach my $table (@tables) {
        run_table($table);
    }

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
    ];
    return $table;
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
    return $table;
}

sub special_expr_table {
    my $sqrt2 = '1.4142135623731';
    my $table = [
        'special expressions',
        [ 'sqrt(2)',          $sqrt2,     'sqrt function' ],
        [ 'length(sqrt(2))',  '14',       'significant digits' ],
        [ 'scale(sqrt(2))',   '13',       'precision digits' ],
    ];
    return $table;
}

sub statement_table {
    ## no critic [ValuesAndExpressions::RequireInterpolationOfMetachars]
    my $table = [
        'statements',
        [    q("a string"),
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

        [   '{ print "a"; print "b"; print "\n" }',
            'ab',
            'compound statement',
        ],

        [   'v=5; while (v--) { print v }; print "\n"',
            "5\n43210",
            'while statement',
        ],

        ## no critic [ValuesAndExpressions::ProhibitInterpolationOfLiterals]
        [   'for (v=0;v<5;v++) { print v }; print "\n"',
            "01234",
            'for statement',
        ],

        [   'for ( v=0; v<5; v++) { print v; if (v>2) break }; print "\n"',
            "01230",
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
    return $table;
}

sub run_table {
    my ($table) = @_;

    my $label = shift @$table;

    subtest $label => sub {
        my ( $fh, $input ) = tempfile();
        foreach my $tuple (@$table) {
            my ( $expr, $expected, $desc ) = @$tuple;
            print {$fh} "$expr\n" or die;
        }
        close $fh or die;

        ## no critic [InputOutput::ProhibitBacktickOperators]
        my $output = `perl $Script $input`;
        my @got    = split /\n/xms, $output;

        # get expected results
        my @expected;
        my @message;
        foreach my $t_ar (@$table) {
            my ( $expr, $exp, $desc ) = @{$t_ar};

            # some operations generate multiple lines of output
            my @lines = split /\n/xms, $exp;
            foreach my $ln (@lines) {
                push @expected, $ln;
                push @message,  $desc . ' : ' . $expr;
            }
        }

        # is @got, @expected, 'count of results';

        foreach my $got (@got) {
            my $exp = shift @expected;
            my $msg = shift @message;
            is $got, $exp, $msg;
        }
    };
    return;
}
