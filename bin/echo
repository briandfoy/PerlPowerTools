#!/usr/bin/perl -w

#
# $Id: echo,v 1.2 2004/08/05 14:17:43 cwest Exp $
#
# $Log: echo,v $
# Revision 1.2  2004/08/05 14:17:43  cwest
# cleanup, new version number on website
#
# Revision 1.1  2004/07/23 20:10:03  cwest
# initial import
#
# Revision 1.0  1999/02/26 01:29:05  randy
# Initial revision
#

use strict;

my ($VERSION) = '$Revision: 1.2 $' =~ /([.\d]+)/;

exit if not @ARGV;

my ($N) = 1;

if ($ARGV [0] eq '-?') {
  $0 =~ s{.*/}{};
  print <<EOF;
Usage: echo [-n] [arguments]

Displays the command line arguments, seperated by spaces.

Options:
       -n:     Do not print a newline after the arguments.
       -?:     Display usage information.
EOF
  exit;
} 

do { $N = 0; shift; } if $ARGV[0] eq '-n';

print join ' ', @ARGV;
print "\n" if $N;

exit;

__END__

=pod

=head1 NAME

echo - echo arguments

=head1 SYNOPSIS

echo [-n] [arguments...]

=head1 DESCRIPTION

echo prints the command line arguments seperated by spaces. A newline is
printed at the end unless the '-n' option is given.

=head2 OPTIONS

I<echo> accepts the following options:

=over 4

=item -n

Do not print a newline after the arguments.

=item -?

Print out a short help message, then exit.

=back

=head1 ENVIRONMENT

The working of I<echo> is not influenced by any environment variables. 

=head1 BUGS

I<echo> has no known bugs.

=head1 REVISION HISTORY

    $Log: echo,v $
    Revision 1.2  2004/08/05 14:17:43  cwest
    cleanup, new version number on website

    Revision 1.1  2004/07/23 20:10:03  cwest
    initial import

    Revision 1.0  1999/02/26 01:29:05  randy
    Initial revision

=head1 AUTHOR

The Perl implementation of I<echo>
was written by Randy Yarger, I<randy.yarger@nextel.com>.

=head1 COPYRIGHT and LICENSE

This program is copyright by Randy Yarger 1999.

This program is free and open software. You may use, modify, distribute
and sell this program (and any modified variants) in any way you wish,
provided you do not restrict others to do the same.

=cut


