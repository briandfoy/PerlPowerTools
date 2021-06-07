#!/usr/bin/env perl
#
# packer.pl - packer for perlpowertools
#
# 2021.05.31 v1.10 jul : fixes spaces in paths and "The command line is too long" (win32) 
# 2021.05.22 v1.00 jul : initial

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
use Cwd qw(abs_path getcwd);
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

# bulid tools list
chdir $ppt_dir;

my @tools_rel = glob("bin/*");
my $tools_rel = join ' ', @tools_rel;

my @tools = map { basename($_) } @tools_rel;
my $tools = join ' ', @tools;

# build helper script
my $ppt_script = do { local(@ARGV, $/); <DATA> };
close DATA;
$ppt_script =~ s/_VERSION_/$VERSION/;
$ppt_script =~ s/_TOOLS_/$tools/;

my $filename = "packer/$program.pl";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh $ppt_script;
close $fh;

# pack
system("pp -v 2 -P -o packed/$program packer/$program.pl $tools_rel") == 0 or die "system failed: $?";

if ($^O eq "MSWin32")
{
	system("pp -v 2 -o packed/$program.exe packer/$program.pl $tools_rel") == 0 or die "system failed: $?";
}

# cleanup
unlink $filename;

exit 1;

__DATA__
use strict;
use warnings;
use utf8;
use Getopt::Std;

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

my $file = "script/$tool";
my $return = do $file;
die $@ if $@;
die "$file: $!" unless defined $return;

exit 1;
