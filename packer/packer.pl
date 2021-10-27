#!/usr/bin/env perl
#
# packer.pl - packer for PerlPowerTools
#
# This script builds :
# 1. 'bin/perlpowertools'        -> helper script (calls unpacked tools from bin/*)
# 2. 'packed/perlpowertools'     -> tools packed as a Perl script (needs external PAR module to run, platform-dependent)
# 3. 'packed/perlpowertools.exe' -> tools packed as a Windows executable (standalone, no dependencies)
#
# The Perl script's shebang and second #line directive are replaced to improve portability,
# provide meaningful error message to the end user and to avoid leaking data (full path of
# perl and parl.pl running 'pp'). This couldn't be done for the Windows executable, because
# it's built in a single step.
#
# 2021.10.22 v1.20 jul : - fixed incorrect tools usage message by setting $0 
#                        - in packed file and helper script : set shebang to #!/usr/bin/env perl
#                        - in packed file : delete "#line 2" directive (line number and file name)
#                        - helper script now in /bin, not deleted anymore, works when packed or not
# 2021.05.31 v1.10 jul : fixed spaces in paths and "The command line is too long" (win32) 
# 2021.05.22 v1.00 jul : initial
#
# TODO
# - find solution for POD

=begin metadata

Name: packer.pl
Description: packer for perlpowertools
Author: jul, kaldor@cpan.org
License: Artistic License 2.0

=end metadata

=cut

use strict;
use warnings;
use utf8;
use Getopt::Std;
use File::Basename;
use File::Glob ':bsd_glob';
use Cwd 'abs_path';
my $ppt_dir;
BEGIN { $ppt_dir = dirname(abs_path($0)) . '/..' };
use lib $ppt_dir . '/lib';
use PerlPowerTools;

our $VERSION = $PerlPowerTools::VERSION;
my $program  = 'perlpowertools';
my $usage    = <<EOF;

Usage: $program [-hV]

    -h, --help      help
    -V, --version   version
EOF

# options
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options = ();
getopts("hV", \%options) or die $usage;

my $help        = $options{h} || 0;
my $version     = $options{V} || 0;

die $usage if $help;
die $VERSION . "\n" if $version;

########
# MAIN #
########

# build tools list
chdir $ppt_dir;

my @tools_rel = glob("bin/*");
@tools_rel = grep { $_ ne "bin/$program" } @tools_rel;
my $tools_rel = join ' ', @tools_rel;

my @tools = map { basename($_) } @tools_rel;
my $tools = join ' ', @tools;

# build helper script
my $ppt_script = do { local(@ARGV, $/); <DATA> };
close DATA;
$ppt_script =~ s/_VERSION_/$VERSION/;
$ppt_script =~ s/_TOOLS_/$tools/;

my $filename = "bin/$program";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh $ppt_script;
close $fh;

# build packed script
system("pp -v 1 -P -o packed/$program bin/$program $tools_rel") == 0 or die "system failed: $?";

# set shebang and remove par.pl line directive
do {
	local $^I='.bak';
	local @ARGV=("packed/$program");
	while(<>) {
		if ($. == 1)
		{
			print "#!/usr/bin/env perl\n";
		}
		elsif ($. > 2)
		{
			print;
		}
	}
	unlink "packed/$program.bak";
};

# build packed executable
if ($^O eq "MSWin32")
{
	system("pp -v 1 -o packed/$program.exe bin/$program $tools_rel") == 0 or die "system failed: $?";
}

exit 1;

__DATA__
#!/usr/bin/env perl
#
# perlpowertools - helper script for PerlPowerTools

use strict;
use warnings;
use utf8;
use Getopt::Std;
use File::Basename;
use Cwd 'abs_path';

our $VERSION = qw( _VERSION_ );
my $program  = 'perlpowertools';
my @tools    = qw( _TOOLS_ );
my $usage    = <<EOF;

Usage: $program [-hVl]
       $program tool [arg ...]

    -h, --help      help
    -V, --version   version
    -l              list tools
EOF

# options
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my %options = ();
getopts("hVl", \%options) or die $usage;

my $help        = $options{h} || 0;
my $version     = $options{V} || 0;
my $list        = $options{l} || 0;

die $usage if $help;
die $VERSION . "\n" if $version;
die join ("\n", @tools) . "\n" if $list;

########
# MAIN #
########

my $tool = shift || '';
die $usage if not grep { $tool eq $_ } @tools;

my $file = defined $ENV{PAR_TEMP} ? "$ENV{PAR_TEMP}/inc/script/$tool" : dirname(abs_path($0)) . "/$tool";
$0 = $tool; # for correct usage message 
my $return = do $file;
die $@ if $@;
die "$file: $!" unless defined $return;

exit 1;
