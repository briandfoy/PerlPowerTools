All programs must work with Perl v5.8. This is a historical contract with users, and PerlPowerTools is mostly useful for ancient Windows systems that can't use wsl.

Each program must be standalone except for core modules that came with v5.8 (try `corelist` to check any module that you'd like to use). We also can't use a common module to provide functionality because that would require keeping track of that file instead of dropping in a single file.

Many of these style preferences come from the dirty work of providing a consistent and proper interface for programs that might be used in a shell program where the exit codes and output matter. We can't take the usual Perl sloppy shortcuts here.

## Basic style

Every script has its own style it seems. Stay close to that when you
make changes.

So far we don't have a perltidy setup for this.

## Don't output extra info from die or warn

End the `die` and `warn` messages with a newline to suppress file and line number messages.

## Don't use $0 directly

The `$0` might have path information in it depending on how the program was invoked. Take the basename of `$0` and assign that to `$Program`, then use `$Program` where you wanted `$0`:

	use File::Basename;
	my $Program = basename($0);

	warn "$Program: some message\n";

## Exit values

Don't just `die`, which exits with 255. Investigate what exit values the actual unix tools use, and program the same things into the program. You might have to run the unix program and look at `$?` to discover what it uses since many man pages do not include this info:

	$ echo Hello
	$ echo $?
	0

Make constants for the exit values. Use these particular names, although you may define more to represent the logical reason. You can have multiple labels for the same value:

	use constant EX_SUCCESS => 0;
	use constant EX_FAILURE => 1;
	use constant EX_OTHER   => 1;
    use constant EX_USAGE   => 2;

	if( ... ) {
		warn "...\n";
		exit EX_FAILURE;
	}

You don't need to exit at the end of the program unless the unix tool would exit with something other than 0 on success.

## Avoid `die` and `warn` handlers

Many programs use `$SIG{__DIE__}` and `$SIG{__WARN__}` in weird ways to adjust exit values and so on. Don't do that, since these affect every `die` or `warn` in their dynamic scope. Instead, output your message and use `exit` right next to it:

	sub usage {
		print ...;
		exit EX_USAGE;
	}

	usage( $message );

## No bareword filehandles or two-argument opens

There are bareword filehandles and two-argument `open`s sprinkled throughout the project. Those can stay, although we'd like to clean up those as well.

Instead, use the three-argument open with the UTF-8 encoding and a lexical filehandle. Always check the return values.

	if( open my $fh, '>:encoding(UTF-8)', $filename ) { ... }

