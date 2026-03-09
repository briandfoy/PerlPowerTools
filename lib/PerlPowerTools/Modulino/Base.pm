package PerlPowerTools::Modulino::Base;
use Carp;
use strict;
use warnings;

eval "no feature qw(module_true)" if $] > 5.39;

=head1 NAME

PerlPowerTools::Modulino::Base - basic functionality for all PerlPowerTools programs

=head1 SYNOPSIS

	package PerlPowerTools::program_name;
	use PerlPowerTools::Modulino::Base;
	our @ISA = qw(PerlPowerTools::Modulino::Base);

	... override what is different ...

	sub program_coderef {
		sub {
			my( $class, $options, $args ) = @_;
			...;
	 		};
	 	}

	exit( __PACKAGE__->run ) unless caller;

=head1 DESCRIPTION

This module is the base class that handles the application framework
for the utilities that L<PerlPowerTools> provides. Those utilities can
subclass this module, override the parts they need to specialize.

This coordinates all the steps to run a program so individual programs
don't have to handle all the tricky details themselves:

=over 4

=item * adjust the environment, such as setting the proper encodings on output handles

=item * process the command-line arguments to decode them and possibly expand globs for shells that don't handle globs

=item * process the options to set option values and separate additional args

=item * run the program

=item * handle exit values

=back

Any of these parts can be overridden in the subclass.

=cut

sub program_coderef {
	die "You must override program_coderef\n";
	}

sub run {
	my( $class ) = @_;

	my $arguments = $class->arguments_glob_resolved;

	my $options;
	( $options, $arguments ) = $class->process_options;

	my $rc = eval {
		$class->program_coderef->( $class, $options, $arguments );
		} or $class->exit(255);

	$class->exit($rc);
	};

=head2 Environment

Probe the environment for certain things that we need to adapt.

=over 4

=item CLASS->is_windows

Returns true if we think we are in a Windows environment. This is not true
for environments on Windows that are trying to pretend to be something else.

=cut

sub is_windows {
	$^O eq 'MSWin32';
	}

=item * CLASS->window_shell

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

=item CLASS->is_powershell

We want to know if we are running from PowerShell, which does its own
globbing.

=cut

BEGIN {
my $is_powershell;

sub is_powershell {
	return $is_powershell if defined $is_powershell;
	my $class = shift;

	my $cmd = $class->windows_shell;

	return $is_powershell = do {
		   if( ! defined $cmd )       { 0 }
		elsif( $cmd =~ /powershell/ ) { 1 }
		else                          { 0 }
		};
	}
}

=back

=head2 Output

This adds an abstraction layer over line-oriented output so we can
easily override it in tests. Some of the programs won't be able to use
this easily, so they should just do what they need to do.

=over 4

=item * CLASS->error(LIST)

Outputs C<LIST> to the result of C<error_fh>.

=item * CLASS->error_fh()

Returns the filehandle for error output. This exists so you can override it,
perhaps by supplying a string filehandle. By default, this is C<STDERR>.

=item * CLASS->output(LIST)

Outputs C<LIST> to the result of C<output_fh>.

=item * CLASS->output_fh()

Returns the filehandle for error output. This exists so you can override it,
perhaps by supplying a string filehandle. By default, this is C<STDOUT>.

=cut

sub error {
	my $class = shift;
	print { $class->error_fh } @_
	}

sub error_fh { \*STDERR }

sub output {
	my $class = shift;
	print { $class->output_fh } @_
	}

sub output_fh { \*STDOUT }

=back

=head2 Argument processing

We need to translate the arguments from their input encoding to UTF-8
so we can use them properly.

=over 4

=item * CLASS->arguments

Returns the original, undecoded arguments as an array reference. These
are I<not> safe to use. By default this is just C<@ARGV>, but you can
override this.

=cut

sub arguments { [ @ARGV ] }

=item * CLASS->arguments_decoded

Returns the decoded arguments as Perl strings. These are safe to use. This
calls C<arguments>.

=cut

sub arguments_decoded {
	my $class = shift;
	my $args = $class->arguments;

	$class->load_module('I18N::Langinfo');
    my $codeset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());

	$class->load_module('Encode');
    my @perl_strings = map { Encode::decode( $codeset, $_ ) } @$args;

	return \@perl_strings;
	}

=item * CLASS->arguments_glob_resolved

Returns the arguments with globs expanded if the shell did not already do
that for us.

=cut

sub arguments_glob_resolved {
	my $class = shift;
	my $decoded = $class->arguments_decoded;
	return $decoded unless $class->needs_to_expand_globs;

	$class->load_module('File::glob');
	my @resolved = ();
	foreach my $arg ( @$decoded ) {
		push @resolved, glob($arg)
		}

	return \@resolved;
	}

=item * CLASS->needs_to_expand_globs

Use this to determine whether the command-line arguments require glob
processing. So far, this should be only C<cmd> on Windows since
Powershell expands globs.

=cut

sub needs_to_expand_globs {
	$_[0]->is_windows and ! $_[0]->is_powershell;
	}

=back

=head2 Option processing

=over 4

=item * CLASS->options_spec

Returns the list of options for L<Getopt::Long>. These are only the
keys for the options spec. Unless overridden this returns the empty
array ref.

	sub options_spec { [ qw( a b c|count=i aardvark )] }

=cut

sub options_spec { [] }

=item * CLASS->process_options

Applies the L<Getopt::Long>, using the options from C<options_spec>.

Returns a hash ref and an array ref. The hash ref is the processed
options, where the keys are the shortest form of the option names.

The array ref is the leftover command-line arguments.

=cut

sub process_options {
	my $class = shift;
	my $spec = $class->options_spec;

	my %opts;
	# options name will be the first letter or the name
	# a            => a
	# a=s          => a
	# a|aardvark   => a
	# a|aardvark=s => a
	# aardvark     => aardvark
	# ...
	my @opts = map {
		my $s = $_;
		$s =~ s/[|=].*//g;
		$_ => \$opts{$s}
		} @$spec;

	$class->load_module("Getopt::Long");
	Getopt::Long::Configure('bundling');

	my @args = @{ $class->arguments_glob_resolved };
	Getopt::Long::GetOptionsFromArray(
		$class->arguments_glob_resolved,
		@opts,
		);

	return \%opts, \@args;
	}

=back

=head2 Exiting

Don't use C<exit> directly since that is onerous to override in tests.

=over 4

=item * CLASS->exit(N)

This calls C<CORE::exit> with the value of C<N>. If C<N> is undefined,
over 255, or under 0, this set C<N> to 1. Any error will C<carp>,
which you should never allow to happen in your program.

=item * CLASS->exit_failure()

Calls C<exit> with the value of C<1>. If you want a different failure
number, call C<exit(N)> directly.

=item * CLASS->exit_signal_n(SIGNAL_NUMBER)

This adds 128 to C<SIGNAL_NUMBER> and calls C<exit(N)> with the
result. You shouldn't have to call this yourself outside of tests. See
C<exit_signal_name>.

=item * CLASS->exit_signal_name(SIGNAL_NAME)

Given a signal name, exit call C<exit_signal_n> with that signal's
number. This is preferable because the signal numbers are not
consistent across systems.

This takes the names and numbers from the L<Config> module, which has
the C<sig_name> and C<sig_num> values.

=item * CLASS->exit_success()

Use this when the program is ready to exit and no errors or problems came
up. Exits with value C<0>.

Note that this is only a convention. Some programs can exit with other values
to indicate types of success. Use C<exit(N)> for those other values.

=item * exit_usage()

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

sub exit_invalid { $_[0]->exit(128) }

sub exit_failure { $_[0]->exit(1) }

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

sub exit_success { $_[0]->exit(0) }

sub exit_usage   { $_[0]->exit(2) }

=cut

=head2 Miscellaneous

=over 4

=item * CLASS->dumper( REF [, REF] )

A nicely-configured L<Data::Dumper>.

=cut

sub dumper {
	my $class = shift;
	require Data::Dumper;
	Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump
	}

=item * CLASS->get_signal_number(NAME)

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

=item * CLASS->load_module( MODULE [, FRIENDLY_MESSAGE] )

Dynamically load C<MODULE>, and if that fails, print a message. If
C<FRIENDLY_MESSAGE> is present, this outputs that message instead of perl's
goobledegook.

=cut

sub load_module {
	my( $class, $module, $message ) = @_;
	unless( $module =~ m/\A[A-Z_][A-Z0-9_]+(?:::[A-Z_][A-Z0-9_]+)*\z/i ) {
		carp "Invalid Perl module name <$module>. This is a problem with the program.";
		$class->exit_failure;
		}

	my $result = eval "require $module; 1";
	my $at = $@;
	unless( defined $result ) {
		$class->error(
			defined $message ? $message : 'Tried to load the Perl module <$module>: $at'
			);
		}
	}

=item * CLASS->program_name

Returns the program name, which should be the last name of the namespace. For
example, for the namespace C<PerlPowerTools::cp>, the program name would be
C<cp>.

If you want a different name, perhaps because the name contains characters that
cannot be in the namespace, override this.

=cut

sub program_name {
	( my $name = ref $_[0] ) =~ s/.*:://;
	}

=item * CLASS->windows_code_page_identifiers

Returns a hash of the code page numbers Windows might return, and the encoding
name that corresponds to that.

=cut

sub windows_code_page_identifiers {
	# compiled by samuel-h-ku in https://github.com/briandfoy/PerlPowerTools/pull/1024
	# https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers
	my %code_page_indentifiers = qw(
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

	return \%code_page_indentifiers;
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
