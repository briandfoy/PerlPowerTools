#!/usr/bin/perl -w
# find - actually a pass through front end for find2perl 

use strict;

my(
   $temp_file,  # file to capture the output of find2perl
   $program,    # results of find2perl for eval
);

END {
  unlink $temp_file;
}

# save standard out so that we can redirect it, then recover original
# standard out

open(SAVE_OUT, ">&STDOUT") || die "can't save stdout: $!";
die unless defined fileno SAVE_OUT;

open(TEMPOUT,"+> " . ($temp_file = "find2perl.$$"))	    ||
open(TEMPOUT,"+> " . ($temp_file = "/tmp/find2perl.$$"))    ||
die "can't find a temp output file";

open(STDOUT, ">&TEMPOUT")    || die "can't dup to $temp_file: $!";
$| = 1;

system 'find2perl', @ARGV;

if ($?) {
  die "Couldn't run find2perl (wait status == $?)";
} 

die "empty program" unless -s TEMPOUT;
die "empty program" unless -s $temp_file;

seek(TEMPOUT, 0, 0)	   || die "can't rewind $temp_file: $!";
$program = do { local $/; <TEMPOUT> };	 # $program now contains file
                                         # contents
close(TEMPOUT)	   || die "can't close $temp_file: $!";
open(STDOUT, ">&SAVE_OUT") || die "can't restore stdout: $!";

eval qq{
  no strict; 
  local \$^W = 0;
  $program;
}; 

if ($@) {
  die "Couldn't compile and execute find-t0-perl program: $@\n";
} 

exit 0;

__END__

=head1 NAME

find - search directory tree for files matching a pattern

=head1 SYNOPSIS

B<find> 
[ -HdhXxW ] 
[ F<Directory> ] 
[ expression ]

=head1 DESCRIPTION

This is actually a front end for B<find2perl>, it automatically
converts your request to perl and executes it (unless something goes
wrong, you probably will not see a difference).  If you want to do
something fancier, or are going to do the same search often, you
should give the commands straight to B<find2perl> and run the perl code
yourself (after possible modification).

B<find> searches a directory tree for files matching given criteria,
then executes user specified commands on those files.

 Examples:

find and print a list of all files on the system (disk) with a F<.pm>
extension (perl modules).  

C<find / -name "*.pl" -print>

find and delete all files in the current directory and subdirectories
that end with F<.bak> and have not been accessed in the last 10 days
(using unix rm command to do the deleting).

C<find . -name "*.bak" -atime +10 -exec rm {};>

=head1 SEE ALSO

find

File/Find.pm

=head1 RESTRICTIONS

I<find2perl> may not cover all the options that various versions of
find implement.  It is only a wrapper to find2perl and so has all the
same restrictions (some have said that find2perl needs updating).

=head1 BUGS

This manpage should probably include the entire 
I<find> manpage, and perhaps that of I<find2perl> as well.

=head1 AUTHOR

This front-end written by Greg Snow, I<snow@biostat.washington.edu>,
with many things "borrowed" from the I<awk> front-end by Tom
Christiansen, I<tchrist@perl.com>.  The I<find2perl> translator was
written by Larry Wall, I<larry@wall.org>, author of Perl.

=head1 COPYRIGHT and LICENSE

This program is copyright (c) Gregory L. Snow 1999
(with parts "borrowed" from things copyright (c) Tom Christiansen 1999).

This program is free and open software. You may use, modify, distribute,
and sell this program (and any modified variants) in any way you wish,
provided you do not restrict others from doing the same.


