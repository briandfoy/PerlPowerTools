/*               -*- Mode: C; tab-width: 8 -*-                          */
/* C-mode seems the best for yacc code, until I write yacc/Perl-mode :) */
/*

 The origin of this file was a test program provided with perl-byacc,
 written by Ray Lischner. Most of it was rewritten, but it was a very
 useful starting point.

 ThB:
 
 To generate the perl file from this byacc source :
 
  byacc -P bc.y
  
 The output is in y.tab.pl
 
 Status:
  I don't have arbitrary precision yet (only standard Perl precision), but
most things work. The exponential function provided in the GNU man page
works.
 
 Done:
 - operators
 - variables
 - parenthesis
 - arbitrary precision
 - arrays
 - user-defined functions seem to work
 - print, {}, if, while, for, return, break
 - quit, length, scale, sqrt
 - / * C-style comments * /

 To do (non-POSIX GNU features are between (), and may not be implemented)
 - check the number of arguments when calling a function
 - (arrays in function parameters)
 - support of hexadecimal (or any base from 11 to 16) values.
 - the 4 special variables : scale, ibase, obase, last.
 - math library : s and c are completely false, j gives wrong results
 for values > 30. Other functions are Ok (cf GNU tests).
 - statements: (continue), (halt)...
 - pseudo-statements: (limit), (warranty)
 - use Readline as an option

 This bc should, at the end, pass the GNU tests, and be able to load the
 GNU math library.

*/
%{


# I don't use BigFloat any more because they lack operators such as **,
# and they're very, very slow
## BigFloat calls a function it does not define
#sub Math::BigFloat::panic { die $_[0];  }
#use Math::BigFloat;

# The symbol table : the keys are the identifiers, the value is in the
# "var" field if it is a variable, in the "func" field if it is a 
# function.
my %sym_table;
my @stmt_list = ();
my @ope_stack;
my @backup_sym_table;
my $input;
my $cur_file = '-';

$debug = 0;
sub debug(&) {
  my $fn = shift;
  print STDERR "\t".&$fn()
    if $debug;
}

#$yydebug=1;

%}

%token INT
%token FLOAT
%token STRING
%token IDENT
%token C_COMMENT

%left	'='
%left	'|'
%left	'&'
%left	'.'

%left   BREAK                               /* "break"                */
%left   DEFINE                              /* "define"               */
%left   AUTO                                /* "auto"                 */
%left   RETURN                              /* "return"               */
%left   PRINT                               /* "print"                */
%left   AUTO_LIST                           /* "var1, var2, var3"     */
%left   IF ELSE                             /* "if", "else"           */
%left   QUIT                                /* "quit"                 */
%left   WHILE                               /* "while"                */
%left   FOR                                 /* "for"                  */

%left	EQ NE                               /* "==", "!="             */
%left	GT GE LT LE                         /* ">", ">=", "<", "<="   */
%left   PP MM                               /* "++", "--" (infix)     */
%left   P_EQ M_EQ F_EQ D_EQ EXP_EQ MOD_EQ   /* "+=", "-=", "*=" etc   */
%left	L_SHIFT R_SHIFT                     /* "<<", ">>"             */
%left   E_E O_O                             /* "&&", "||"             */
%left	'+' '-'   
%left	'*' '/'
%left   '%'
%left   '(' ')'
%left   '{' '}'
%left	'!'
%right	EXP                                 /* "^", "**"              */
%right	UNARY
%right  PPP MMM                             /* "++", "--" (postfix)   */

%start	stmt_list_exec

%%

stmt_list_exec:	/* empty */
	|	stmt_list_exec stmt_exec
	;

stmt_exec:      terminator
        |       stmt_compile terminator     
                { 

		  my ($res, $val) = exec_stmt(shift @stmt_list); 
		  if($res == 0 and defined($val) and 
		     $cur_file ne 'main::DATA') {
		    print "$val\n";
		  }
		  start_stmt();
		}
	|	error terminator  
                { 
		  @ope_stack = (); 
		  @stmt_list = ();
		  start_stmt();
		  &yyerrok; 
		}
        ;

stmt_compile:   QUIT { exit(0); }

	|       DEFINE
                { 
		  start_stmt(); 
		}
                IDENT '(' arg_list ')' terminator_or_void
		'{' terminator
		auto_list
                { 
		  start_stmt(); 
		  start_stmt();
		}
                stmt_list_block
		'}'
                {
		  finish_stmt();    # The last one is empty
		  push_instr('RETURN', 0);
		  my $body = finish_stmt();
		  push_instr('{}', $body);
		  my $code = finish_stmt();
		  push_instr('FUNCTION-DEF', $3, $code);
                }

        |       return

        |       BREAK                    { push_instr('BREAK'); }

        |       PRINT
                {
		  push_instr(',');
		  start_stmt(); 
		  start_stmt(); 
		}
                expr_list_commas
                {
		  finish_stmt();  # The last one is empty
		  my $stmt = finish_stmt();
		  push_instr('PRINT', $stmt);
		}

        |       '{'                             
                { 
		  start_stmt(); 
		  start_stmt();
		}
		stmt_list_block '}'
                {
		  finish_stmt();  # The last one is empty
		  my $stmt = finish_stmt();
		  push_instr('{}', $stmt);
		}

        |       IF '(' stmt_compile ')'         { start_stmt(); }
                terminator_or_void
                stmt_compile
                {
		  my $stmt = finish_stmt();
		  push_instr('IF', $stmt);
		}

        |       WHILE                          { start_stmt(); }
                '(' stmt_compile_or_void ')' terminator_or_void            
                { 
		  my $stmt = finish_stmt();
		  push_instr('FOR-COND', $stmt);
                  start_stmt();
                }
                stmt_compile
                {
		  my $stmt = finish_stmt();
		  push_instr('FOR-INCR', []);
		  push_instr('FOR-BODY', $stmt);
		}

        |       FOR '(' stmt_compile_or_void ';'       { start_stmt(); }
	        stmt_compile_or_void ';' 
                {
		  my $stmt = finish_stmt();
		  push_instr('FOR-COND', $stmt);
		  start_stmt();
		}
                stmt_compile_or_void ')'
                {
		  my $stmt = finish_stmt();
		  push_instr('FOR-INCR', $stmt);
		  start_stmt();
		} terminator_or_void stmt_compile
                { 
		  my $stmt = finish_stmt();
		  push_instr('FOR-BODY', $stmt);
		}
                		 
	|	expr

	;

return:        RETURN                  { push_instr('RETURN', 0); }
         |     RETURN '(' expr ')'     { push_instr('RETURN', 1); }
         ;

stmt_compile_or_void: /* empty */
         |     stmt_compile
         ;

stmt_list_block: stmt_compile_or_void
                 {
		   my $stmt = finish_stmt();
		   if(scalar(@$stmt) > 0) {
		     push_instr('STMT', $stmt);
		   }
		   start_stmt();
		 }
        |        stmt_list_block terminator stmt_compile_or_void
                 {
		   my $stmt = finish_stmt();
		   if(scalar(@$stmt) > 0) {
		     push_instr('STMT', $stmt);
		   }
		   start_stmt();
		 }
        ;

terminator_or_void:
                /* empty */
        |       terminator
        ;

terminator:	';'
	|	'\n'
	;

arg_list:       /* empty */
        |       arg_list_nonempty
        ;

arg_list_nonempty:
                IDENT                        { push_instr('a', $1); }
        |       arg_list_nonempty ',' IDENT  { push_instr('a', $3); }
        ;

param_list:      /* empty */
        |        param_list_nonempty
        ; 

param_list_nonempty:
	        expr
        |       param_list_nonempty ',' expr
        ;

auto_list:      /* empty*/
        |       AUTO auto_list_nonempty terminator
        ;

auto_list_nonempty:
                IDENT                         { push_instr('A', $1); }
        |       auto_list_nonempty ',' IDENT  { push_instr('A', $3); }
        ;

expr_list_commas: 
	        expr
                {
		  my $stmt = finish_stmt();
		  push_instr('PRINT-STMT', $stmt);
		  start_stmt();
		}
        |       expr_list_commas ',' expr
                {
		  my $stmt = finish_stmt();
		  push_instr('PRINT-STMT', $stmt);
		  start_stmt();
		}

expr:
                IDENT '('
                param_list ')'  
                { 
		  push_instr('FUNCTION-CALL', $1);
		}

        |	'(' expr ')' { }

        |	expr O_O expr     { push_instr('||_'); }
	|	expr E_E expr     { push_instr('&&_'); }

        |	expr EQ expr      { push_instr('==_'); }
        |	expr NE expr      { push_instr('!=_'); }
        |	expr GT expr      { push_instr('>_'); }
        |	expr GE expr      { push_instr('>=_'); }
        |	expr LT expr      { push_instr('<_'); }
        |	expr LE expr      { push_instr('<=_'); }
        |	expr L_SHIFT expr { push_instr('<<_'); }
        |	expr R_SHIFT expr { push_instr('>>_'); }

        |	expr '+' expr { push_instr('+_'); }
        |	expr '-' expr { push_instr('-_'); }
        |	expr '*' expr { push_instr('*_'); }
        |	expr '/' expr { push_instr('/_'); }
        |	expr EXP expr { push_instr('^_'); }
        |	expr '%' expr { push_instr('%_'); }

        # See PPP for comments
        |	ident P_EQ expr                 # +=
                { 
		  push_instr('+_');
		  push_instr('V', $1);
		  push_instr('=V');
		}
	|	ident M_EQ expr                 # -=
                { 
		  push_instr('-_');
		  push_instr('V', $1);
		  push_instr('=V');
		}
	|	ident F_EQ expr                 # *=
                { 
		  push_instr('*_');
		  push_instr('V', $1);
		  push_instr('=V');
		}
	|	ident D_EQ expr                 # /=
                { 
		  push_instr('/_');
		  push_instr('V', $1);
		  push_instr('=V'); 
		}
	|	ident EXP_EQ expr               # **=
                { 
		  push_instr('^_');
		  push_instr('V', $1);
		  push_instr('=V'); 
		}
	|	ident MOD_EQ expr               # %=
                { 
		  push_instr('%_');
		  push_instr('V', $1);
		  push_instr('=V'); 
		}

#        |	expr '!' { push_instr('!_'); }

	|	'-' expr		%prec UNARY
		{ 
		  push_instr('m_');
		}
	|	'!' expr		%prec UNARY
		{ 
		  push_instr('!_');
		}
	|	PP ident                            # "++x"
		{ 
		  # 'v'.$2 has already been pushed in the 'ident' rule
		  push_instr('N', 1);
		  push_instr('+_');
		  push_instr('V', $2);
		  push_instr('=V');
		}
	|	MM ident                            # "--x"
		{ 
		  push_instr('N', 1);
		  push_instr('-_');
		  push_instr('V', $2);
		  push_instr('=V');
		}
	|	ident PPP                           # "x++"
		{
		  # $1 is already on the stack (see the "ident:" rule)
		  push_instr('v', $1)     ;
		  push_instr('V', '*tmp') ; 
		  push_instr('=V')        ;  # *tmp = $1
		  push_instr(',')         ;

		  push_instr('N', 1)      ;    
		  push_instr('+_')        ;
		  push_instr('V', $1)     ;
		  push_instr('=V')        ;  # $1 = $1 + 1
		  push_instr(',')         ;
			    
		  push_instr('v', '*tmp') ;  # Return *tmp

		}
	|	ident MMM                   # "x--"
		{ 
		  # See PPP for comments
		  push_instr('v', $1);
		  push_instr('V', '*tmp');
		  push_instr('=V');
		  push_instr(',');
		  push_instr('N', 1);
		  push_instr('-_');
		  push_instr('V', $1);
		  push_instr('=V');
		  push_instr(',');
		  push_instr('v', '*tmp');
		}
	|	'+' expr		%prec UNARY
		{ $$ = $2; }
	|	'&' STRING		%prec UNARY
		{ 
		  push_instr('&', $2);
		  $$ = 1;
		}

        |       IDENT '=' expr
                {
		  push_instr('V', $1);
		  push_instr('=V');
		  $$ = $3;
		}
        |       IDENT '[' expr ']' '=' expr
                {
		  # Add [] to the name in order to allow the same name
		  # for an array and a scalar
		  push_instr('P', $1);
		  push_instr('=P');
		  $$ = $6;
		}

	|	ident  { $$ = $1->{"value"}; }

	|	INT    { push_instr('N', $1); }
        |	FLOAT  { push_instr('N', $1); }
        |	STRING { push_instr('S', $1); }

	;

ident:          IDENT { push_instr('v', $1); }

        |       IDENT '[' expr ']'
                { 
		  push_instr('p', $1); 
		  $$ = $1.'[]'.$3;
		}
        ;
%%

# Prompt the user on STDERR, but only prompt if STDERR and the input
# file are both terminals.

@file_list=();
$mathlib=0;
sub command_line()
{
  while ($f = shift(@ARGV)) {
    if ($f eq '-d') {
      use Data::Dumper;
      $debug = 1;
    } elsif ($f eq '-y') {
      $yydebug = 1;
    } elsif ($f eq '-l') {
      $mathlib = 1;
    } else {
      push(@file_list, $f);
    }
  }
# read from STDIN if no files are named on the command line
  @file_list = ('-') if $#file_list < 0;
}


# After finishing a file, open the next one.  Return whether there
# really is a next one that was opened.
sub next_file
{
  if($cur_file) {
    close $input;
  }

  if($mathlib) {

    debug { "reading the math library\n" };

    $input = \*main::DATA;
    $mathlib=0;
    $cur_file="main::DATA";
    return 1;

  } elsif($file = shift(@file_list)) {

    debug { "reading from $file\n" };

    if (! open(IN, $file)) {
      die "$file: cannot open file: $!\n";
    }
    $input = IN;
    $cur_file = $file;
    $prompt = '';
    return 1;

  }

  debug { "no next file\n" };

  return 0;
}

# print the prompt
sub prompt
{
    print STDERR $prompt if $prompt;
}

# print an error message
sub yyerror
{
    print STDERR "\"$cur_file\", " if $cur_file ne '-';
#    debug { "yyerror-stmt_list : ".Dumper(\@stmt_list) };

    print STDERR "line $.: ", @_, "\n";

    @ope_stack = ();
    start_stmt();
}

# Hand-coded lex
sub yylex
{
 lexloop: {
   # get a line of input, if we need it.
   if ($line eq '')
	{
	  &prompt;
	  while(! ($line = <$input>)) {
	      &next_file || do { 
		return(0); };
	  }
	}

	# Skip over white space, and grab the first character.
	# If there is no such character, then grab the next line.
	$line =~ s/^\s*(.|\n)//	|| next lexloop;
	local($char) = $1;

	if ($char eq '/' and $line =~ /^\*/) {
          # C-style comment
 	  while($line !~ m%\*/%) {
	    $line = <$input>;
	  }
	  $line =~ s%.*?\*/% %;
	  yylex();
	} 

        elsif ($char eq '#') {
	  # comment, so discard the line
	  $line = "\n";
	  &yylex;

	} elsif ($char eq '\\' and $line eq "\n") {

	  # Discard the newline
	  $line = '';
	  yylex();

	} elsif ($char =~ /^(['"])/) {

          $yylval = "";

          my $c = $1;
 	  while($line !~ /$c/) {
            $yylval .= $line;
	    $line = <$input>;
	  }

	  $line =~ s%(.*?)$c% %;
          $yylval .= $1;

	    $STRING;

	} elsif ($char =~ /^[\dA-F]/ or 
		 ($char eq '.' and $line =~ /\d/)) {

          # Bug: hexadecimal values are not supported, because they are
          # not supported in Math::BigFloat
	  # I should support them myself

	  if($char =~ /[A-F]/) {
	    &yyerror('Sorry, hexadecimal values are not supported');
	  }

	  $line = "0.$line" if($char eq '.');
 
          # number, is it integer or float?
	  if ($line =~ s/^(\d+)//) {
#	      $yylval = Math::BigFloat->new($char . $1);
	      $yylval = 0 + ($char.$1);
          } else {
#	      $yylval = Math::BigFloat->new($char);
	      $yylval = 0 + $char;
	  }
	  $type = $INT;
	  
	  if ($line =~ s/^(\.\d*)//) {
	      $tmp = "0$1";
	      $yylval += $tmp;
	      $type = $FLOAT;
	  }
	  if ($line =~ s/^[eE]([-+]*\d+)//) {
	      $yylval *= 10 ** $1;
	      $type = $FLOAT;
	  }

	  $type;
	  
     } elsif ($char =~ /^[a-z]/) {   
          # Uppercase is reserved for hexadecimal numbers
	  $line =~ s/^([\w\d]*)//;
	  $yylval = $char.$1;

	  if($yylval eq 'auto') {
	    $AUTO;
	  } elsif($yylval eq 'break') {
	    $BREAK;
	  } elsif($yylval eq 'define') {
	    $DEFINE;
	  } elsif($yylval eq 'for') {
	    $FOR;
	  } elsif($yylval eq 'if') {
	    $IF;
	  } elsif($yylval eq 'else') {
	    $ELSE;
	  } elsif($yylval eq 'print') {
	    $PRINT;
	  } elsif($yylval eq 'quit') {
	    $QUIT;
	  } elsif($yylval eq 'return') {
	    $RETURN;
	  } elsif($yylval eq 'while') {
	    $WHILE;
	  } else {
	    $IDENT;
	  }

	} elsif (($char eq '*' && $line =~ s/^\*=//) or
                 ($char eq '^' && $line =~ s/=//)) {
	    $EXP_EQ;
	} elsif (($char eq '*' && $line =~ s/^\*//) or
                 ($char eq '^')) {
	    $EXP;

	} elsif ($char eq '|' && $line =~ s/^\|//) {
	    $O_O;
	} elsif ($char eq '&' && $line =~ s/^&//) {
	    $E_E;

	} elsif ($char eq '%' && $line =~ s/^=//) {
	    $MOD_EQ;
	} elsif ($char eq '!' && $line =~ s/^=//) {
	    $NE;
	} elsif ($char eq '=' && $line =~ s/^=//) {
	    $EQ;

	} elsif ($char =~ /^[<>]/ && $line =~ s/^=//) {
	    $char eq '<' ? $LE : $GE;
	} elsif ($char =~ /^[<>]/ && $line =~ s/^$char//) {
	    $char eq '<' ? $L_SHIFT : $R_SHIFT;
	} elsif ($char =~ /^[<>]/) {
	    $char eq '<' ? $LT : $GT;

 	} elsif ($char eq '+' && $line =~ s/^\+(\s*\w)/$1/) {
	    $PP;
	} elsif ($char eq '+' && $line =~ s/^=//) {
	    $P_EQ;
	} elsif ($char eq '+' && $line =~ s/^\+//) {
	    $PPP;
	} elsif ($char eq '-' && $line =~ s/^\-(\s*\w)/$1/) {
	    $MM;
	} elsif ($char eq '-' && $line =~ s/^\-//) {
	    $MMM;
	} elsif ($char eq '-' && $line =~ s/^=//) {
	    $M_EQ;
	} elsif ($char eq '*' && $line =~ s/^=//) {
	    $F_EQ;
	} elsif ($char eq '/' && $line =~ s/^=//) {
	    $D_EQ;
	} else {
	    $yylval = $char;
	    ord($char);
	}
    }
}

# factorial
sub fact
{
    local($n) = @_;
    local($f) = 1;
    $f *= $n-- while ($n > 1) ;
    $f;
}

sub bi_length
{
  my $stack = shift;
  
  $_ = pop @$stack;
  
  my ($a, $b);
  die "NaN" unless ($a, $b) = /[-+]?(\d*)\.?(\d+)?/;
  
  $a =~ s/^0+//;  
  $b =~ s/0+$//;

  my $len = length($a) + length($b);
  
  return $len == 0 ? 1 : $len;
}


sub bi_scale
{
  my $stack = shift;
  
  $_ = pop @$stack;
  
  my ($a, $b);
  die "NaN" unless ($a, $b) = /[-+]?(\d*)\.?(\d+)?/;

  return length($b);
}

sub bi_sqrt
{
  my $stack = shift;
  
  $_ = pop @$stack;
  
  return sqrt($_);
}

# Initialize the symbol table
sub init_table
{
  $sym_table{'scale'} = { type => 'var', value => 0};
  $sym_table{'ibase'} = { type => 'var', value => 0};
  $sym_table{'obase'} = { type => 'var', value => 0};
  $sym_table{'last'} = { type => 'var', value => 0};
  $sym_table{'length()'} = { type => 'builtin', 
			   value => \&bi_length };
  $sym_table{'scale()'} = { type => 'builtin', 
			   value => \&bi_scale };
  $sym_table{'sqrt()'} = { type => 'builtin', 
			   value => \&bi_sqrt };
}

#
# Pseudo-code
#

# Compilation time: a stack of statements is maintained. Each statement
# is itself a stack of instructions.
# Each instruction is appended to the statement which is on the top.
# When a sub-block (IF, DEFINE...) is encountered, a
# new, empty statement is pushed onto the stack, and it receives the
# instructions in the sub-block.

my $cur_stmt;


# Pushes one instruction onto the current statement
# First element is the type, others are 0 or more arguments, depending on
# the type.
sub push_instr
{
  die "Internal error: no cur stmt" unless($cur_stmt);
  my @args = @_;
  push(@$cur_stmt, [ @args ]);
}

# Pushes a new statement onto the stack of statements, and makes it the
# current
sub start_stmt
{
  $cur_stmt = [];
  push(@stmt_list, $cur_stmt);
}

# Closes a statement, and returns a reference on it.
sub finish_stmt
{
  my $stmt = pop @stmt_list;
  $cur_stmt = $stmt_list[$#stmt_list];
  return $stmt;
}


#
# Execution time
#

my ($res, $val);
my $res2;
my $code;

sub exec_print
{
  my $res = exec_stmt(@_);
  print "$res\n" if(defined $res);
}

#
# exec_stmt
# Really executes a statement. Calls itself recursively when it
# encounters sub-statements (in block, loops, functions...)
#  
my $count = 0;
sub exec_stmt
{
$count++;
  my $stmt = shift;

  my $return = 0; # 1 if a "return" statement is encountered
  
  my @stmt_s = @$stmt;
#  print STDERR "ko\n";"executing statement: ".Dumper(\@stmt_s);
  
  
# Each instruction in the stack is an array which first element gives
# the type. Others elements may contain references to sub-statements
  
  my $instr;
  
 INSTR: while (defined($instr = shift @stmt_s)) {

   $_ = $instr->[0]; 
      
   print STDERR ("instruction: ".join(', ', @$instr)."\n" ) if $debug;
      
# remove the stack top value, and forget about it
   if($_ eq ',') {
     $res = pop @ope_stack;
     next INSTR;

   } elsif($_ eq 'N') {

# N for number
     push(@ope_stack, 0 + $instr->[1]);
     next INSTR;

   } elsif($_ eq '+_'  or $_ eq '-_'  or $_ eq '*_'  or $_ eq '/_'  or 
	   $_ eq '^_'  or $_ eq '%_'  or $_ eq '==_' or $_ eq '!=_' or 
	   $_ eq '>_'  or $_ eq '>=_' or $_ eq '<_'  or $_ eq '<=_' or 
	   $_ eq '<<_' or $_ eq '>>_' or $_ eq '||_' or $_ eq '&&_') {

# Binary operators
	  my $b = pop(@ope_stack); my $a = pop(@ope_stack);
	  
	  if   ($_ eq '+_') { $res = $a + $b    ; 1 }
	  elsif($_ eq '-_') { $res = $a - $b    ; 1 }
	  elsif($_ eq '*_') { $res = $a * $b    ; 1 }
	  elsif($_ eq '/_') { $res = $a / $b    ; 1 }
	  elsif($_ eq '^_') { $res = $a ** $b   ; 1 }
	  elsif($_ eq '%_') { $res = $a % $b    ; 1 }

	  elsif($_ eq '==_') { $res = 0 + ($a == $b) ; 1 }
	  elsif($_ eq '!=_') { $res = 0 + ($a != $b) ; 1 }
	  elsif($_ eq '>_')  { $res = 0 + ($a > $b)  ; 1 }
	  elsif($_ eq '>=_') { $res = 0 + ($a >= $b) ; 1 }
	  elsif($_ eq '<_')  { $res = 0 + ($a < $b)  ; 1 }
	  elsif($_ eq '<=_') { $res = 0 + ($a <= $b) ; 1 }

	  elsif($_ eq '<<_') { $res = ($a << $b) ; 1 }
	  elsif($_ eq '>>_') { $res = ($a >> $b) ; 1 }

	  elsif($_ eq '||_') { $res = ($a || $b) ? 1 : 0 ; 1 }
	  elsif($_ eq '&&_') { $res = ($a && $b) ? 1 : 0 ; 1 }

	  ;
	      
	  push(@ope_stack, $res);
	  next INSTR;


# Unary operators

   } elsif($_ eq 'm_') {

     $res = pop(@ope_stack);
     push(@ope_stack, -$res);
     next INSTR;

   } elsif($_ eq '!_') {

     $res = pop(@ope_stack);
     push(@ope_stack, 0+!$res);
     next INSTR;

   } elsif($_ eq 'V') {

# Variable or array identifier
     push(@ope_stack, $instr->[1]);
     next INSTR;

   } elsif($_ eq 'P') {

     push(@ope_stack, $instr->[1].'[]'.(pop(@ope_stack)));
     next INSTR;

   } elsif($_ eq 'v') {

# Variable value
# '*' is reserved for internal variables

     my $name = $instr->[1];
     unless (defined($sym_table{$name}) 
	     and $sym_table{$name}{'type'} eq 'var') {
       print STDERR "$name: undefined variable\n";
       $return = 3;
       @ope_stack = ();
       @stmt_list=();
       YYERROR;
     }
     push(@ope_stack, $sym_table{$name}{'value'});
     next INSTR;

   } elsif($_ eq 'p') {

# Array value : initialized to 0
     my ($name, $idx) = ($instr->[1], pop(@ope_stack));

     if($idx !~ /^\d+$/) {
       print STDERR "Non-integer index $idx for array\n";
       $return = 3;
       @ope_stack = ();
       @stmt_list=();
       YYERROR;
     }
       
#     debug {"p: $name, $idx.\n"};
     unless (defined($sym_table{$name.'[]'})
	     and $sym_table{$name.'[]'}{'type'} eq 'array') {

       $sym_table{$name.'[]'} = { type => 'array'};
     }
     unless ($sym_table{$name.'[]'}{'value'}[$idx]) {
       $sym_table{$name.'[]'}{'value'}[$idx] = { type => 'var',
					    value => 0 };
     }
     push(@ope_stack, $sym_table{$name.'[]'}{'value'}[$idx]{'value'});
     next INSTR;
     
   } elsif($_ eq '=V') { 
      
# Attribution of a value to a variable
# ope_stack ends with a NUMBER and an IDENTIFIER
     my $varName = pop(@ope_stack);
     my $value = pop(@ope_stack);
     $sym_table{$varName} = { type => 'var',
			      value => $value };
     push(@ope_stack, $value);
     next INSTR;

   } elsif($_ eq '=P') {
   
     my $varName = pop(@ope_stack);
     my $value = pop(@ope_stack);
     my ($name, $idx) = ($varName =~ /([a-z]+)\[\](\d+)/);

     $name .= '[]';
     unless (defined($sym_table{$name})
	     and $sym_table{$name}{'type'} eq 'array') 
     {
       $sym_table{$name} = { type => 'array',
			     value => [] };
     }
     $sym_table{$name}{'value'}[$idx] = { type => 'var',
					  value => $value };
     push(@ope_stack, $value);
     next INSTR;

   } elsif($_ eq 'IF') {
# IF statement

     my $cond = pop @ope_stack;
     my $res = $cond;
     $val = 0;
     if($cond) {
       ($return, $val) = exec_stmt($instr->[1]);
       push(@ope_stack, $val), last INSTR if $return;
     }

#     debug {"IF: $val.\n"};
     push(@ope_stack, $val);
#     debug {"IF: ope_stack=".Dumper(\@ope_stack)};
     next INSTR;

   } elsif($_ eq 'FOR-COND') {
# WHILE and FOR statement

#     debug {"while-cond: stmt_s=".Dumper(\@stmt_s)};

     my $i_cond = $instr;
     my $i_incr = shift @stmt_s;
     my $i_body = shift @stmt_s;
     
     my $r;
     my $val=1;

#     debug { "cond: ".Dumper($i_cond) };

   LOOP: while(1) {

     @ope_stack=();
     if($#{ $i_cond->[1] } >= 0) {
       ($return, $val) = exec_stmt($i_cond->[1]);
#       debug {"results of cond: $return, $val"};
       push(@ope_stack, $val), last INSTR 
	 if($return == 1 or $return == 2);
       last LOOP if $val == 0;
     }
     
#     debug {"while: executing a body\n"};
     
     if($#{ $i_body->[1] } >= 0) {
       ($return, $val) = exec_stmt($i_body->[1]);
       push(@ope_stack, $val);
       
       if($return == 1) {
	 last INSTR;
       } elsif($return == 2) {
	 $return = 0 ;
	 last INSTR;
       }
     }
     
     if($#{ $i_incr->[1] } >= 0) {
#       debug {"for: executing the increment: ".Dumper($i_incr)};
       @ope_stack = ();
       ($return, $val) = exec_stmt($i_incr->[1]);
	 push(@ope_stack, $val);
	 last INSTR if($return == 1 or $return == 2);
     }
     
   }
     $return = 3;
     push(@ope_stack, 1);  # whatever
     next INSTR;

   } elsif($_ eq 'FUNCTION-CALL') {

# Function call
     push @backup_sym_table, undef;   # Hmmm...

     my $name = $instr->[1];
     $name .= '()';

     unless($sym_table{$name}) {
       print STDERR "No function $name has been defined\n";
       @ope_stack = (0);
       $return = 3;
       YYERROR;
     } 

     if($sym_table{$name}{type} eq 'builtin') {
       ($return, $val) = 
	 (1, &{ $sym_table{$name}{value} }(\@ope_stack));
     } else {
       ($return, $val) = exec_stmt($sym_table{$name}{'value'});

# Restore the symbols temporarily pushed in 'a' and 'A' instructions
       debug {"restoring backup: ".Dumper(\@backup_sym_table)};

       my $n;
#       pop @backup_sym_table;    # The first is undef
       my $entry;
       while($var = pop @backup_sym_table) {
	 debug {"restoring var: ".Dumper($var)};
	 if($var->{'type'} eq 'undef') {
	   delete $sym_table{$var->{'name'}};;
	 } else {
	   $sym_table{$var->{'name'}} = $var->{'entry'};
	 }
       }

#       push @backup_sym_table, undef;
     }

#     debug {"result from function $name: $return, $val.\n"};
     push(@ope_stack, $val);

     if($return == 1) {
       $return = 0; # so the result will be printed
     } elsif($return == 2) {
       print STDERR "No enclosing while or for";
       YYERROR;
     } elsif($return == 3) {
       $return = 0;
     }
     next INSTR;

   } elsif($_ eq 'a' or $_ eq  'A') {

# Function arguments and auto list declaration
# The difference is that function arguments are initialized from the
# operation stack, while auto variables are initialized to zero
     my ($where, $name) = ($_, $instr->[1]);
  
     if(defined $sym_table{$name}) {
       debug { "backup $name, $sym_table{$name}\n" };
       push @backup_sym_table,  { name => $name,
				    entry => $sym_table{$name} }; 
     } else {
       debug { "backup $name, undef \n" };
       push @backup_sym_table,  { name => $name,
				    type => 'undef' }; 
     } 
     $sym_table{$name} = { type => 'var',
			   value => ($where eq 'a' ? 
				     shift(@ope_stack) : 0) };
     
#     debug { "new entry $name in sym table: $sym_table{$name}{'value'}" };
     next INSTR;

   } elsif($_ eq '{}') {

# Grouped statements
     if(scalar @{ $instr->[1] } > 0) {
       ($return, $val) = exec_stmt($instr->[1]);
     } else {
       ($return, $val) = (0, 0);
     }

     push(@ope_stack, $val), last INSTR 
       if($return eq 1 or $return eq 2);

     $return = 3;
     push(@ope_stack, $val);
     next INSTR;

   } elsif($_ eq 'STMT') {
     
     @ope_stack=();
     if(scalar $instr->[1] > 0) {
       ($return, $val) = exec_stmt($instr->[1]);
     } else {
       ($return, $val) = (3, undef);
     }

     @ope_stack = ($val), last INSTR 
	if($return eq 1 or $return eq 2);

     $return = 3;
     @ope_stack = ($val);

     next INSTR;

   } elsif($_ eq 'RETURN') {
# Return statement
     
#     debug {"returning $instr->[1].\n"};
     my $value = ($instr->[1] == 0) ? 0
       : pop(@ope_stack);

     $return = 1;
     @ope_stack = ($value);

     last INSTR;

   } elsif($_ eq 'BREAK') {
# Break statement
     
#     debug {"breaking.\n"};

     $return = 2;
     push(@ope_stack, 0);

     last INSTR;

   } elsif($_ eq 'PRINT') {
# PRINT statement

     if(scalar @{ $instr->[1] } > 0) {
       ($return, $val) = exec_stmt($instr->[1]);
     } else {
       ($return, $val) = (0, 0);
     }

     push(@ope_stack, $val), last INSTR 
       if($return eq 1 or $return eq 2);

     $return = 3;
     next INSTR;

   } elsif($_ eq 'PRINT-STMT') {

     @ope_stack=();
     if(scalar $instr->[1] > 0) {
       ($return, $val) = exec_stmt($instr->[1]);
     } else {
       ($return, $val) = (3, undef);
     }

     last INSTR if($return eq 1 or $return eq 2);

     $return = 3;

     print $val;
     next INSTR;

   } elsif($_ eq 'FUNCTION-DEF') {

# Function definition
     my ($name, $code) = ($instr->[1], $instr->[2]);
     push(@$code, ["RETURN", 0]);
     $sym_table{$name.'()'} = { type => 'func',
				value => $code };
     $return = 3;
     push(@ope_stack, 1); # whatever
     next INSTR;

   } elsif($_ eq '&') {

# Evaluating a Perl instruction
     $res = eval $instr->[1];
     push(@ope_stack, "\nresult of eval: $res");
     next INSTR;

   } elsif($_ eq 'S') {

# S for string
     $_ = $instr->[1];
     s/ \\a  /\a/gx;
     s/ \\b  /\b/gx;
     s/ \\f  /\f/gx;
     s/ \\n  /\n/gx;
     s/ \\r  /\r/gx;
     s/ \\t  /\t/gx;
     s/ \\q  /"/gx;   # "
     s/ \\\\ /\\/gx; 
     push(@ope_stack, $_); 
     next INSTR;

   } else {
     
     die "internal error: illegal statement $_";

   }
   
 }
  
  my $val;
  if ($return == 3) {
    @ope_stack = ();
  } else {
    if(scalar @ope_stack != 1) {
      die("internal error: ope_stack = ".join(", ", @ope_stack).".\n");
    }
 
    $val = pop(@ope_stack);
#    debug {"Returning ($return, $val)\n"};
#    debug {"ope_stack at e-o-func: ".Dumper(\@ope_stack)};
  }

  return ($return, $val);

}

# catch signals
sub catch
{
  local($signum) = @_;
  print STDERR "\n" if (-t STDERR && -t STDIN);
  &yyerror("Floating point exception") if $signum == 8;
#  next outer;
  main();
}

# main program
sub main
{
# outer: 
  while(1)
    {
      $line = '';
      eval '$status = &yyparse;';
#      debug { "yyparse returned $status" } if !$@;
      exit $status if ! $@;
      &yyerror($@);
    }
}

init_table();

command_line();

$SIG{'INT'} = 'catch';
$SIG{'FPE'} = 'catch';

select(STDERR); $| = 1;
select(STDOUT);
&next_file;

start_stmt();

main();

print "count=$count\n";

__END__

/* libmath.b for GNU bc.  */

/*  This file is part of GNU bc.
    Copyright (C) 1991, 1992, 1993, 1997 Free Software Foundation, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License , or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; see the file COPYING.  If not, write to
    the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

    You may contact the author by:
       e-mail:  phil@cs.wwu.edu
      us-mail:  Philip A. Nelson
                Computer Science Department, 9062
                Western Washington University
                Bellingham, WA 98226-9062
       
*************************************************************************/


scale = 20

/* Uses the fact that e^x = (e^(x/2))^2
   When x is small enough, we use the series:
     e^x = 1 + x + x^2/2! + x^3/3! + ...
*/

define e(x) {
  auto  a, d, e, f, i, m, n, v, z

  /* a - holds x^y of x^y/y! */
  /* d - holds y! */
  /* e - is the value x^y/y! */
  /* v - is the sum of the e's */
  /* f - number of times x was divided by 2. */
  /* m - is 1 if x was minus. */
  /* i - iteration count. */
  /* n - the scale to compute the sum. */
  /* z - orignal scale. */

  /* Check the sign of x. */
  if (x<0) {
    m = 1
    x = -x
  } 

  /* Precondition x. */
  z = scale;
  n = 6 + z + .44*x;
  scale = scale(x)+1;
  while (x > 1) {
    f += 1;
    x /= 2;
    scale += 1;
  }

  /* Initialize the variables. */
  scale = n;
  v = 1+x
  a = x
  d = 1

  for (i=2; 1; i++) {
    e = (a *= x) / (d *= i)
    if (e == 0) {
      if (f>0) while (f--)  v = v*v;
      scale = z
      if (m) return (1/v);
      return (v/1);
    }
    v += e
  }
}

/* Natural log. Uses the fact that ln(x^2) = 2*ln(x)
    The series used is:
       ln(x) = 2(a+a^3/3+a^5/5+...) where a=(x-1)/(x+1)
*/

define l(x) {
  auto e, f, i, m, n, v, z

  /* return something for the special case. */
  if (x <= 0) return ((1 - 10^scale)/1)

  /* Precondition x to make .5 < x < 2.0. */
  z = scale;
  scale = 6 + scale;
  f = 2;
  i=0
  while (x >= 2) {  /* for large numbers */
    f *= 2;
    x = sqrt(x);
  }
  while (x <= .5) {  /* for small numbers */
    f *= 2;
    x = sqrt(x);
  }

  /* Set up the loop. */
  v = n = (x-1)/(x+1)
  m = n*n

  /* Sum the series. */
  for (i=3; 1; i+=2) {
    e = (n *= m) / i
    if (e == 0) {
      v = f*v
      scale = z
      return (v/1)
    }
    v += e
  }
}

/* Sin(x)  uses the standard series:
   sin(x) = x - x^3/3! + x^5/5! - x^7/7! ... */

define s(x) {
  auto  e, i, m, n, s, v, z

  /* precondition x. */
  z = scale 
  scale = 1.1*z + 2;
  v = a(1)
  if (x < 0) {
    m = 1;
    x = -x;
  }
  scale = 0
  n = (x / v + 2 )/4
  x = x - 4*n*v
  if (n%2) x = -x

  /* Do the loop. */
  scale = z + 2;
  v = e = x
  s = -x*x
  for (i=3; 1; i+=2) {
    e *= s/(i*(i-1))
    if (e == 0) {
      scale = z
      if (m) return (-v/1);
      return (v/1);
    }
    v += e
  }
}

/* Cosine : cos(x) = sin(x+pi/2) */
define c(x) {
  auto v;
  scale += 1;
  v = s(x+a(1)*2);
  scale -= 1;
  return (v/1);
}

/* Arctan: Using the formula:
     atan(x) = atan(c) + atan((x-c)/(1+xc)) for a small c (.2 here)
   For under .2, use the series:
     atan(x) = x - x^3/3 + x^5/5 - x^7/7 + ...   */

define a(x) {
  auto a, e, f, i, m, n, s, v, z

  /* a is the value of a(.2) if it is needed. */
  /* f is the value to multiply by a in the return. */
  /* e is the value of the current term in the series. */
  /* v is the accumulated value of the series. */
  /* m is 1 or -1 depending on x (-x -> -1).  results are divided by m. */
  /* i is the denominator value for series element. */
  /* n is the numerator value for the series element. */
  /* s is -x*x. */
  /* z is the saved user's scale. */

  /* Negative x? */
  m = 1;
  if (x<0) {
    m = -1;
    x = -x;
  }

  /* Special case and for fast answers */
  if (x==1) {
    if (scale <= 25) return (.7853981633974483096156608/m)
    if (scale <= 40) return (.7853981633974483096156608458198757210492/m)
    if (scale <= 60) \
      return (.785398163397448309615660845819875721049292349843776455243736/m)
  }
  if (x==.2) {
    if (scale <= 25) return (.1973955598498807583700497/m)
    if (scale <= 40) return (.1973955598498807583700497651947902934475/m)
    if (scale <= 60) \
      return (.197395559849880758370049765194790293447585103787852101517688/m)
  }


  /* Save the scale. */
  z = scale;

  /* Note: a and f are known to be zero due to being auto vars. */
  /* Calculate atan of a known number. */ 
  if (x > .2)  {
    scale = z+5;
    a = a(.2);
  }
   
  /* Precondition x. */
  scale = z+3;
  while (x > .2) {
    f += 1;
    x = (x-.2) / (1+x*.2);
  }

  /* Initialize the series. */
  v = n = x;
  s = -x*x;

  /* Calculate the series. */
  for (i=3; 1; i+=2) {
    e = (n *= s) / i;
    if (e == 0) {
      scale = z;
      return ((f*a+v)/m);
    }
    v += e
  }
}


/* Bessel function of integer order.  Uses the following:
   j(-n,x) = (-1)^n*j(n,x) 
   j(n,x) = x^n/(2^n*n!) * (1 - x^2/(2^2*1!*(n+1)) + x^4/(2^4*2!*(n+1)*(n+2))
            - x^6/(2^6*3!*(n+1)*(n+2)*(n+3)) .... )
*/
define j(n,x) {
  auto a, d, e, f, i, m, s, v, z

  /* Make n an integer and check for negative n. */
  z = scale;
  scale = 0;
  n = n/1;
  if (n<0) {
    n = -n;
    if (n%2 == 1) m = 1;
  }

  /* Compute the factor of x^n/(2^n*n!) */
  f = 1;
  for (i=2; i<=n; i++) f = f*i;
  scale = 1.5*z;
  f = x^n / 2^n / f;

  /* Initialize the loop .*/
  v = e = 1;
  s = -x*x/4
  scale = 1.5*z

  /* The Loop.... */
  for (i=1; 1; i++) {
    e =  e * s / i / (n+i);
    if (e == 0) {
       scale = z
       if (m) return (-f*v/1);
       return (f*v/1);
    }
    v += e;
  }
}
