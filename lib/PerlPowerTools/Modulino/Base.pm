package PerlPowerTools::Modulino::Base;
use strict;
use warnings;

use Carp                  qw(carp croak);
use Config                qw(%Config);
use File::Spec::Functions qw(catfile);
use Storable              qw(dclone);

eval "no feature qw(module_true)" if $] > 5.39;

=head1 NAME

PerlPowerTools::Modulino::Base - basic functionality for all PerlPowerTools programs

=head1 SYNOPSIS

	package PerlPowerTools::program_name;
	use PerlPowerTools::Modulino::Base;
	our @ISA = qw(PerlPowerTools::Modulino::Base);

	... override what is different ...

	sub main {
		my( $program ) = @_;

		return $exit_value;
	 	}

=head1 DESCRIPTION

This module is the base class that handles the application framework
for the utilities that L<PerlPowerTools> provides. Those utilities can
subclass this module, override the parts they need to specialize, and let
the rest happen for them.

This coordinates all the steps to run a program so individual programs
don't have to handle all the tricky details themselves:

=over 4

=item * adjust the environment, such as setting the proper encodings on output handles

=item * process the command-line arguments to decode them and possibly expand globs for shells that don't handle globs

=item * process the options to set option values and separate additional args

=item * run the program

=item * handle exit values

=back

Anything that you want to change should be done through a subclass where you
override the method. The use of override-able methods makes these things easy
to test.

=head2 Methods you must define

=over 4

=item * main

The C<main> method represents the bulk of your program. This should be everything
between option processing and exiting. The only argument is the program instance
object, which has access to everything. This should return the exit value of the
program (but don't call C<exit>!.

See the section on L</Exit Values>, which has many methods that return particular
exit values. If your program does not use the convention exit values, override the
ones you need to change.

=cut

sub main {
	die "You must override program()\n";
	}

=item * handle_main_failure

C<run> wraps the call to C<main> in an C<eval>. If the C<eval> catches an error,
C<run> calls C<handle_main_failure> with the value of C<$@>.

By default this outputs to the error filehandle the value of C<$@>, then exits
with C<exit_code_program_failure>.

=cut

sub handle_main_failure {
	my( $self, $at ) = @_;

	$self->error( $@ );
	$self->exit_code_program_failure;
	}

=item * program_name

Returns the program name, which should be the last part of the Perl namespace. For
example, for the namespace C<PerlPowerTools::cp>, the program name would be
C<cp>.

If you want a different name, perhaps because the name contains characters that
cannot be in the namespace, override this.

=cut

sub program_name {
	( my $name = ref $_[0] ) =~ s/.*:://;
	return $name;
	}

=back

=head2 Program instance construction

=over 4

=item * new(ARGS)

Creates a blessed hash ref with one key: C<start_time>, then calls C<init>
with C<ARGS>.

Instead of overriding C<new>, you should probably handle everything in C<init>.

=cut



sub new {
	my( $class, @args ) = @_;
	my $self = bless { start_time => time }, $class;
	$self->init(@args);
	$self;
	}

=item * init

By default this does nothing, but this is called in C<new> after it creates
the program instance.

=cut

sub init {
	return 1;
	}

=item * run

This actually runs the program by calling C<process_options>, calling C<main>,
and using the return value of C<main> as value it sends to the C<exit> method.

=cut

sub run {
	my( $either ) = @_;

	my $program = ref $either ? $either : $either->new;

	$program->process_options;

	my $rc = do {
		if($program->had_option_errors && $program->stop_on_option_error) {
			$program->exit_code_usage
			}
		else {
			my $rc = eval { $program->main };
			$rc = $program->handle_main_failure($@) if $@;
			$rc;
			}
		};

	$program->exit($rc);
	};

=back

=head2 Platform details

Probe the platform for certain things that we need to adapt.

=over 4

=item is_windows

Returns true if we think we are in a Windows environment. This is not true
for environments on Windows that are trying to pretend to be something else.

=cut

sub is_windows {
	$^O eq 'MSWin32';
	}

=item * window_shell

Attempts to determine which shell invoked this program. C<cmd> and
C<powershell> need different treatment.

=cut

sub windows_shell {
	return unless $_[0]->is_windows;

	eval {
		my $wmic_output = `wmic process where processid=$$ get parentprocessid /value`;
		my( $ppid ) = $wmic_output =~ /=(\d+)/;

		my @tasklist = `tasklist /FO CSV /NH /FI "PID eq $ppid"`;
		my( $cmd ) = $tasklist[0] =~ /\A"(.+?)"/;

		return $cmd;
		};

	return;
	}

=back

=head2 Windows size

=over 4

=item default_columns

=cut

sub default_columns { 80 }

=item * get_columns

Attempts to get the width of the terminal. If it can't do that, it uses
the value returned by C<default_columms>.

=cut

sub get_columns {
	my($self) = @_;

	my $columns = do {
		if( $self->is_windows ) {
			my @lines = `powershell -command "&{(get-host).ui.rawui.WindowSize;}"`;

			while( my $l = shift @lines ) { last if $l =~ /\A-----/ }
			return $lines[0] =~ m/\A\s*(\d+)/ ? $1 : ();
			}
		elsif( has('tput') ) { `tput cols` }
		elsif( has('stty') ) { `stty size  | cut -d' ' -f 2` }
		else                 { () }
		};

	$columns = $self->default_columns unless defined $columns;
	chomp $columns;
	return $columns + 0;
	}

=item * has(COMMAND)

Searches the C<PATH> for C<COMMAND> and returns the path it finds, or the empty
list.

=cut

sub has {
	my( $self, $program ) = @_;
	foreach my $dir ( split /\Q$Config{path_sep}/, $ENV{PATH} ) {
		next unless -x catfile( $dir, $program );
		return 1;
		}
	return;
	}

=back

=head2 Program details

=over 4

=item * start_time

Returns the time that the program started.

=cut

sub start_time { $_[0]->{'start_time'} }

=back

=head2 Output

This adds an abstraction layer over line-oriented output so we can
easily override it in tests. Some of the programs won't be able to use
this easily, so they should just do what they need to do.

=over 4

=item * debug(LIST)

Outputs C<LIST> to the result of C<error_fh> if C<am_debugging> returns true.
Otherwise, nothing is output.

This is the value of C<debugging> in the program instance.

=item * debug_fh

Returns the filehandle for error output. This exists so you can override it,
perhaps by supplying a string filehandle. By default, this is C<STDERR>.

=item * error(LIST)

Outputs C<LIST> to the result of C<error_fh> if C<is_silent> returns false.
Otherwise, nothing is output.

Use this where you would use standard error.

=item * error_fh

Returns the filehandle for error output. This exists so you can override it,
perhaps by supplying a string filehandle. By default, this is C<STDERR>.

=item * is_silent

Returns true if the program wants to run in silent mode (with no output).

This is the value of C<silent> in the program instance.

=item * output(LIST)

Outputs C<LIST> to the result of C<output_fh> if C<is_silent> returns false.
Otherwise, nothing is output.

Use this where you would use standard output.

=item * output_fh

Returns the filehandle for standard output. This exists so you can override it,
perhaps by supplying a string filehandle. By default, this is C<STDOUT>.

=cut

sub am_debugging { $_[0]->{debugging} || 0 }

sub debug {
	my($self) = shift;
	return unless $self->am_debugging;
	print { $self->debug_fh } @_
	}

sub debug_fh { \*STDERR }

sub error { my($self) = shift; print { $self->error_fh } @_ }

sub error_fh { \*STDERR }

sub input_fh { \*STDIN }

sub is_silent { $_[0]->{silent} || 0 }

sub output {
	my($self) = shift;
	return if $self->is_silent;
	print { $self->output_fh } @_
	}

sub output_fh { \*STDOUT }

sub single_line_input { scalar readline $_[0]->input_fh }

=back

=head2 Argument processing

We need to translate the arguments from their input encoding to Perl strings
so we can use them properly.

=over 4

=item * arguments

Returns the portion of the command line left over after options have been
processed.

If called before option processing, this is the same as C<command_line>. Option
processing will set the value for this method.

=cut

sub arguments {
	my($self) = @_;
	$self->{'arguments'} = $self->command_line unless defined $self->{'arguments'};
	return $self->{'arguments'};
	}

=item * command_line_decoded

Returns the decoded command line as Perl strings. These are safe to use. This
uses the result of C<command_line> and has the values before any option
processing.

=cut

sub command_line_decoded {
	my($self) = @_;
	my $args = $self->command_line;

	$self->load_module('I18N::Langinfo');
    my $codeset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());

	if($self->is_windows) {
		my $h = $self->windows_code_page_identifiers;
		if(exists $h->{$codeset}){
			$codeset = $h->{$codeset};
			}
		}

	$self->load_module('Encode');
    my @perl_strings = map { Encode::decode( $codeset, $_ ) } @$args;

	$self->{'decoded_command_line'} = dclone \@perl_strings;
	}

=item * command_line

Return the undecoded command line (without the program name) as an array
ref. By default, this is just C<@ARGV>. This allows tests (and programs)
to override where arguments come from.

This should always be the original command line as the program received it
and before the program processed it. Different shells may process a command
line differently

=cut

sub command_line { dclone \@ARGV }

=item * command_line_glob_resolved

Returns the command line with globs expanded if the shell did not already do
that for us as controlled by C<needs_to_expand_globs>.

This is a lot more tricky than it seems.

If a glob does not find any matching files, the result is the literal
string that was the glob. For example, if C<*.txt2> matches nothing, then
the literal C<*.txt2> is the resolved argument.

On

=cut

sub command_line_glob_resolved {
	my($self) = @_;
	return $self->{'resolved_command_line'} if defined $self->{'resolved_command_line'};

	my $decoded = $self->command_line_decoded;
	return $decoded unless $self->needs_to_expand_globs;

	$self->load_module('File::Glob');
	my @resolved = ();
	foreach my $arg ( @$decoded ) {
		if( -e $arg ) {
			push @resolved, $arg
			}
		else {
			my @files = glob($arg);
			if(@files) { push @resolved, @files }
			else { push @resolved, $arg }
			}
		}

	$self->{'resolved_command_line'} = dclone \@resolved;
	}

=item * needs_to_expand_globs

Use this to determine whether the command-line arguments require glob
processing. So far this is the same as C<is_windows>.

=cut

sub needs_to_expand_globs {
	$_[0]->is_windows
	}

=back

=head2 Option processing

Everything is done with L<Getopt::Long>, although you can override all of
that.

=over 4

=item * had_option_errors

Returns true if there were option errors.

=cut

sub had_option_errors {
	my($self) = @_;
	!! $self->{'option_errors'}
	}

=item * option_error

Called for each warning raised by L<Getopt::Long>. By default, each message is
sent unchanged to C<error>.

=cut

sub option_error {
	my( $self, @args ) = @_;
	$self->{'option_errors'} += @args;
	$self->error( "option error: $_" ) for @args;
	}

=item * options

Return the options hash created by C<process_options>.

=cut

sub options { $_[0]->{options} }

=item * options_spec

Returns the list of options for L<Getopt::Long>. These are only the
keys for the options spec. Unless overridden this returns the empty
array ref.

	sub options_spec { [ qw( a b c|count=i aardvark )] }

Each option value will be stored in a hash. You can handle options
errors with C<option_error>.

=cut

sub options_spec { [] }

=item * postprocess_arguments

A hook called after L<Getopt::Long> has done its work and allows you to fix
up the list of arguments after options processing has been done.

=cut

sub postprocess_arguments { return }

=item * postprocess_options

A hook called inside C<process_options> before it does anything.

=cut

sub postprocess_options { return }

=item * preprocess_arguments

A hook called before L<Getopt::Long> has done its work. This is here for
parallel structure, but L<process_options> is likely to overwrite anything
you do.

=cut

sub preprocess_arguments { return }

=item * preprocess_options

A hook to preprocess the command line before C<process_options>. By default it
does nothing.

=cut

sub preprocess_options { return }

=item * process_options

Applies the L<Getopt::Long>, using the options from C<options_spec>. The
option values are stored as a hash in the C<options> key in the instance,
which you can get through C<options>. The leftover command-line values
are stored as an array ref in the C<args> key in the instance.

Before any work is done, this calls C<preprocess_arguments> and
C<preprocess_options> so that programs can fix up anything it needs to
modify before L<Getopt::Long> does its work. For example, some programs
have weird edge cases that are easier to handle by adding or subtracting
values from the command line before processing.

Likewise, after all work is done, this calls C<postprocess_arguments> and
C<postprocess_options> to modify the work that L<Getopt::Long> did. For
example, some programs have options that are actually shorthand for
turning on collections of other options, such as C<ls -f> implying C<-a>.
That can happen here.

All L<Getopt::Long> warnings are passed to C<option_error> so you can
modify the warnings. By default, each warning is sent to C<error>.

=cut

sub process_options {
	my($self) = @_;

	$self->preprocess_arguments;
	$self->preprocess_options;

	# options name will be the first letter or the name
	# a            => a
	# a=s          => a
	# a|aardvark   => a
	# a|aardvark=s => a
	# aardvark     => aardvark
	# ...
	my %opts;
	my $spec = $self->options_spec;
	my @opts = map {
		my $s = $_;
		$s =~ s/[|=].*//g;
		$_ => \$opts{$s}
		} @$spec;

	my @args = @{ $self->command_line_glob_resolved };
	$self->{'resolved_command_line'} = [ @args ];

	{
	$self->load_module("Getopt::Long");
	local $SIG{'__WARN__'} = sub { $self->option_error(@_) };
	Getopt::Long::Configure( qw(bundling no_ignore_case) );
	Getopt::Long::GetOptionsFromArray(
		\@args,
		@opts,
		);
	}

	$self->{'options'}   = \%opts;
	$self->{'arguments'} = \@args;

	$self->postprocess_arguments;
	$self->postprocess_options;

	return $self->had_option_errors;
	}

=item * stop_on_option_error

Some programs will want to stop for option erros, while others will continue.
You can handle errors yourself with C<option_error>, override C<had_option_errors>
to return 0, or unset C<option_errors> in the program instance.

By default this returns true.

=cut

sub stop_on_option_error { 1 }

=back

=head2 Environment

=over 4

=item * is_interactive_terminal

Returns true if it thinks this is an interactive session. Some programs will
implicitly sety options based on their estimation of interactivity.

=cut

# stolen directly from IO::Interactive
sub is_interactive_terminal {
    my ($out_handle) = (@_, select);    # Default to default output handle

    # Not interactive if output is not to terminal...
    return 0 if not -t $out_handle;

    # If *ARGV is opened, we're interactive if...
    if ( tied(*ARGV) or defined(fileno(ARGV)) ) { # this is what 'Scalar::Util::openhandle *ARGV' boils down to

        # ...it's currently opened to the magic '-' file
        return -t *STDIN if defined $ARGV && $ARGV eq '-';

        # ...it's at end-of-file and the next file is the magic '-' file
        return @ARGV>0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;

        # ...it's directly attached to the terminal
        return -t *ARGV;
    }

    # If *ARGV isn't opened, it will be interactive if *STDIN is attached
    # to a terminal.
    else {
        return -t *STDIN;
    }
}

=back

=head2 Exiting

Don't use C<exit> directly since that is onerous to override in tests. This is
handled in C<run>.

There are two sets of methods: ones that exit, and ones that provide values
for exit. The default values are for the conventional Unix program return values,
but not every Unix program follows those conventions.

=over 4

=item * exit(N)

This calls C<CORE::exit> with the value of C<N>. If C<N> is undefined,
over 255, or under 0, this set C<N> to 1. Any error will C<carp>,
which you should never allow to happen in your program.

=item * exit_failure

Calls C<exit> with the value of C<1>. If you want a different failure
number, call C<exit(N)> directly, or override this method.

=item * exit_signal_n(SIGNAL_NUMBER)

This adds 128 to C<SIGNAL_NUMBER> and calls C<exit(N)> with the
result. You shouldn't have to call this yourself outside of tests. See
C<exit_signal_name>.

=item * exit_signal_name(SIGNAL_NAME)

Given a signal name, exit call C<exit_signal_n> with that signal's
number. This is preferable because the signal numbers are not
consistent across systems.

This takes the names and numbers from the L<Config> module, which has
the C<sig_name> and C<sig_num> values.

=item * exit_success

Use this when the program is ready to exit and no errors or problems came
up. Exits with value from C<exit_code_success>.

Note that this is only a convention. Some programs can exit with other values
to indicate types of success.

=item * exit_usage

Exits with value C<2>. By convention, this is used when the invocation is improper
in some way, such as missing arguments or unsupported arguments.

Although this is a convention, not all original utilities use C<2> as their exit
value for this. Use whatever the original BSD utilty used.

=cut

sub exit {
	my( $class, $n ) = @_;

	my $message = do {
		if( ! defined $n ) { "exit value undefined" }
		elsif( $n > 255 )  { "exit value over 255" }
		elsif( 1 == length $n and $n eq '0' ) { () }
		elsif( $n < 0 )    { "exit value under 0" }
		};

	if( defined $message and length $message ) {
		carp $message;
		$n = 1;
		}

	CORE::exit($n)
	}

sub exit_code_program_failure { 255 }

sub exit_code_failure { 1 }

sub exit_code_invalid { 128 }

sub exit_code_success { 0 }

sub exit_code_usage   { 2 }

sub exit_invalid { $_[0]->exit( $_[0]->exit_code_invalid ) }

sub exit_failure { $_[0]->exit( $_[0]->exit_code_failure ) }

sub exit_signal_n  {
	my( $class, $n ) = @_;

	my $message = do {
		if( ! defined $n ) { "signal value undefined" }
		elsif( $n > 127 )  { "signal value over 127" }
		elsif( 1 == length $n and $n eq '0' ) { () }
		elsif( $n < 1 )    { "exit value under 1 -> using 1 instead" }
		};

	if( defined $message ) {
		carp $message;
		return $class->exit_failure;
		}
	else {
		$class->exit(128 + $n)
		}
	}

sub exit_signal_name  {
	my( $class, $name ) = @_;
	my $n = get_signal_number($name);
	unless( defined $n ) {
		carp("No number for signal <$name>");
		return $class->exit_failure;
		}

	$class->exit(127 + $n)
	}

sub exit_success { $_[0]->exit( $_[0]->exit_code_success ) }

sub exit_usage   { $_[0]->exit( $_[0]->exit_code_usage   ) }

=cut

=head2 Miscellaneous

=over 4

=item * dumper( REF [, REF] )

A nicely-configured L<Data::Dumper> that returns a string.

=cut

sub dumper {
	my($self) = shift;
	require Data::Dumper;
	Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump
	}

=item * get_signal_number(NAME)

Turn the signal C<NAME> into its number for this B<perl>. These numbers are not
consistent across systems, so don't assume you know what the number is.

The C<NAME> is the same as the string you'd use in a signal handler:

	local $SIG{'TERM'} = sub { ... };

=cut

sub get_signal_number {
	require Config;
    my( $sig_name ) = @_;
    my %sig_num;

	my @arrays =
		map  { [ split /\s+/, $Config::Config{$_} ] }
		grep { exists $Config::Config{$_} }
		qw(sig_name sig_num);

	return unless @arrays == 2;
	return unless @{ $arrays[0] } == @{ $arrays[1] };

	my %sig_hash = map { uc($arrays[0][$_]), $arrays[1][$_] } 0 .. $#{ $arrays[0] };

	exists $sig_hash{uc($sig_name)} ? $sig_hash{uc($sig_name)} : ();
	}

=item * load_module( MODULE [, FRIENDLY_MESSAGE] )

Dynamically load C<MODULE>, and if that fails, output a message. If
C<FRIENDLY_MESSAGE> is present, this outputs that message instead of perl's
goobledegook.

=cut

sub load_module {
	my( $self, $module, $message ) = @_;

	unless( $module =~ m/\A[A-Z_][A-Z0-9_]+(?:::[A-Z_][A-Z0-9_]+)*\z/i ) {
		carp "Invalid Perl module name <$module>. This is a problem with the program.";
		$self->exit_failure;
		}

	my $result = eval "require $module; 1";
	my $at = $@;
	if( $at ) {
		$self->error( "Could not load <$module>: $at\n ");
		}
	unless( defined $result ) {
		$self->error(
			defined $message ? $message : 'Tried to load the Perl module <$module>: $at'
			);
		}
	}

=item * windows_code_page_identifiers

Returns a hash of the code page numbers Windows might return, and the encoding
name that corresponds to that.

=cut

sub windows_code_page_identifiers {
	# compiled by samuel-h-ku in https://github.com/briandfoy/PerlPowerTools/pull/1024
	# https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
	my %code_page_identifiers = qw(
		  37 IBM037
		 437 IBM437
		 500 IBM500
		 708 ASMO-708
		 720 DOS-720
		 737 ibm737
		 775 ibm775
		 850 ibm850
		 852 ibm852
		 855 IBM855
		 857 ibm857
		 858 IBM00858
		 860 IBM860
		 861 ibm861
		 862 DOS-862
		 863 IBM863
		 864 IBM864
		 865 IBM865
		 866 cp866
		 869 ibm869
		 870 IBM870
		 874 windows-874
		 875 cp875
		 932 shift_jis
		 936 gb2312
		 949 ks_c_5601-1987
		 950 big5
		1026 IBM1026
		1047 IBM01047
		1140 IBM01140
		1141 IBM01141
		1142 IBM01142
		1143 IBM01143
		1144 IBM01144
		1145 IBM01145
		1146 IBM01146
		1147 IBM01147
		1148 IBM01148
		1149 IBM01149
		1200 utf-16
		1201 unicodeFFFE
		1250 windows-1250
		1251 windows-1251
		1252 windows-1252
		1253 windows-1253
		1254 windows-1254
		1255 windows-1255
		1256 windows-1256
		1257 windows-1257
		1258 windows-1258
		1361 Johab
		10000 macintosh
		10001 x-mac-japanese
		10002 x-mac-chinesetrad
		10003 x-mac-korean
		10004 x-mac-arabic
		10005 x-mac-hebrew
		10006 x-mac-greek
		10007 x-mac-cyrillic
		10008 x-mac-chinesesimp
		10010 x-mac-romanian
		10017 x-mac-ukrainian
		10021 x-mac-thai
		10029 x-mac-ce
		10079 x-mac-icelandic
		10081 x-mac-turkish
		10082 x-mac-croatian
		12000 utf-32
		12001 utf-32BE
		20000 x-Chinese_CNS
		20001 x-cp20001
		20002 x_Chinese-Eten
		20003 x-cp20003
		20004 x-cp20004
		20005 x-cp20005
		20105 x-IA5
		20106 x-IA5-German
		20107 x-IA5-Swedish
		20108 x-IA5-Norwegian
		20127 us-ascii
		20261 x-cp20261
		20269 x-cp20269
		20273 IBM273
		20277 IBM277
		20278 IBM278
		20280 IBM280
		20284 IBM284
		20285 IBM285
		20290 IBM290
		20297 IBM297
		20420 IBM420
		20423 IBM423
		20424 IBM424
		20833 x-EBCDIC-KoreanExtended
		20838 IBM-Thai
		20866 koi8-r
		20871 IBM871
		20880 IBM880
		20905 IBM905
		20924 IBM00924
		20932 EUC-JP
		20936 x-cp20936
		20949 x-cp20949
		21025 cp1025
		21866 koi8-u
		28591 iso-8859-1
		28592 iso-8859-2
		28593 iso-8859-3
		28594 iso-8859-4
		28595 iso-8859-5
		28596 iso-8859-6
		28597 iso-8859-7
		28598 iso-8859-8
		28599 iso-8859-9
		28603 iso-8859-13
		28605 iso-8859-15
		29001 x-Europa
		38598 iso-8859-8-i
		50220 iso-2022-jp
		50221 csISO2022JP
		50222 iso-2022-jp
		50225 iso-2022-kr
		50227 x-cp50227
		51932 euc-jp
		51936 EUC-CN
		51949 euc-kr
		52936 hz-gb-2312
		54936 GB18030
		57002 x-iscii-de
		57003 x-iscii-be
		57004 x-iscii-ta
		57005 x-iscii-te
		57006 x-iscii-as
		57007 x-iscii-or
		57008 x-iscii-ka
		57009 x-iscii-ma
		57010 x-iscii-gu
		57011 x-iscii-pa
		65000 utf-7
		65001 utf-8
		);

	return \%code_page_identifiers;
	}

=back

=head1 AUTHOR

brian d foy, E<lt>briandfoy@pobox.comE<gt>

=head1 COPYRIGHT and LICENSE

Copyright © 2026-2026 brian d foy. All rights reserved.

You may use this program under the terms of the Artistic License 2.0.

=cut

no warnings;
__PACKAGE__;
