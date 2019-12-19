package PerlPowerTools;
use strict;
use warnings;

=encoding utf8

=head1 The build file for PerlPowerTools

This build file is a modulino; it works as both a build script and
a module.

To build the distribution, run this file normally:

	% perl Makefile.PL

If you didn't specify C<INSTALL_BASE>, the modules go into your home
directory under F<perlpowertools>. You'll need to add this to PATH to
be able to use them.

If you want to install them somewhere else, run the F<Makefile.PL>
with your installation location:

    % perl Makefile.PL INSTALL_BASE=/where/you/want/them/to/go

But, this F<Makefile.PL> is more interesting than that. You can load
it with C<require> and call C<arguments> to get the data structure it
passes to C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module). Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

# You can specify INSTALL_BASE on the command line or in an environment
# variable a tool sets. We should respect either of them.
my $install_base_in_argv        = grep { /\AINSTALL_BASE\b/ } @ARGV;
my $install_base_in_perl_mm_opt = (defined $ENV{PERL_MM_OPT} ? $ENV{PERL_MM_OPT} : "") =~ /\bINSTALL_BASE\b/;
my $has_install_base =
	$install_base_in_argv || $install_base_in_perl_mm_opt || 0;

use File::Spec::Functions qw(catfile);
my $home = home();
unless( $has_install_base ) {
	my $path = catfile($home, 'perlpowertools');
	print <<"HERE";
----------------------------------------------------------------------
Welcome to Perl Power Tools (http://www.perlpowertools.com).

You didn't specify INSTALL_BASE, so I chose $path.
You'll need to add this to PATH to be able to use the Perl Power Tools.

If you want to install them somewhere else, run Makefile.PL again
with your installation location:

    perl Makefile.PL INSTALL_BASE=/where/you/want/them/to/go

Most Perl distributions don't do this for you, but I'm doing this
because some of these tools installed in the wrong places can hide
the real tools, which might cause problems. I'm being careful for
you!
----------------------------------------------------------------------
HERE

	push @ARGV, "INSTALL_BASE=$path";
	}

my @exe_files = glob "bin/*";


my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/PerlPowerTools';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.008',

	'NAME'          => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'EXE_FILES'     => \@exe_files,

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		},

	'TEST_REQUIRES' => {
		'Test::More' => '1',
		},

	'PREREQ_PM'     => {
		'App::a2p'       => '0',
		'App::find2perl' => '0',
		'Make'           => '0',
		'MIME::Parser'   => '0',
		'DB_File'        => '0',
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => "$github.git",
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
				},
			homepage => "https://www.perlpowertools.com/",
			},
		},

	clean => { FILES => "$dist-*" },
	);


sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	WriteMakefile( %$arguments );
	}


sub home {
	if ($^O eq 'MSWin32') {
		#stolen from File::HomeDir::Windows
		if ( exists $ENV{HOME} and $ENV{HOME} ) {
			return $ENV{HOME};
		}

		if ( exists $ENV{USERPROFILE} and $ENV{USERPROFILE} ) {
			return $ENV{USERPROFILE};
		}

		if ( exists $ENV{HOMEDRIVE} and exists $ENV{HOMEPATH} and $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {
			return catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '' )
		}
	} else {

		return '~';
	}
}

no warnings;
__PACKAGE__;
