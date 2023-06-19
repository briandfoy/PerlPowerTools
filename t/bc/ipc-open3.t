use strict;
use warnings;

use lib qw(./t/lib);

use Test::More;
use Symbol ();
use FileHandle;
use Time::HiRes qw(usleep);
use IO::Select;

my $program = 'bin/bc';

foreach my $table ( special_expr_table() ) {# operator_table(), precedence_table(), special_expr_table(), statement_table() ) {
	my $label = shift @$table;
	subtest $label => sub {
		foreach my $tuple ( @$table ) {
			my $hash = run_bc( $tuple->[0] );
			is $hash->{output}, $tuple->[1] . "\n", $tuple->[2];
			}
		}
	}

sub run_bc {
	# https://www.perlmonks.org/?node_id=419919
	my( $input ) = @_;

	my $class = require './bin/bc';
	print "Class is <$class>\n";

	chomp($input); $input .= "\n";

	my %hash = ( input => $input );
	print STDERR Dumper(\%hash); use Data::Dumper;
	open $PerlPowerTools::bc::INPUT_FH, '>', \ $hash{info};
	open $PerlPowerTools::bc::ERROR_FH, '>', \ $hash{error};
	open $PerlPowerTools::bc::DEBUG_FH, '>', \ $hash{debug};
	open $PerlPowerTools::bc::VALUE_FH, '>', \ $hash{value};

	print "About to run\n";
	eval { $class->run('-d', '-') };
	print "Already ran\n";

	print STDERR Dumper(\%hash); use Data::Dumper;

	return \%hash;
	}

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
    return $table;
}

done_testing();

