Thanks for putting me in touch with my roots.
# --cut here--
#! /bin/sh
# To unshar, remove everything before the "cut here" line
# and feed the result to /bin/sh
sed -e 's/^X//' >shar <<'FUNKY_STUFF'
X#! /usr/bin/perl
X# public domain code by salzr@certo.com
X# (formerly rsalz@osf.org, rsalz@bbn.com, mirror!rs)
X
Xrequire 'getopts.pl';
X
Xsub
XUsage
X{
X    print STDERR "@_.\nUsage: $av0 files...\n";
X    exit(1);
X}
X
X# Parse JCL.
X$av0 = $0;
X$av0 =~ s@.*/@@;
X&Getopts("") || &Usage("Usage error");
X
X# Do work.
X$dirty = 0;
XARGUMENT: foreach $f ( @ARGV ) {
X    if ( ! open(FH, $f) ) {
X	warn "$av0: can't open $f, $!\n";
X	next ARGUMENT;
X    }
X
X    if ( $dirty++ == 0 ) {
X	print '# --cut here--
X#! /bin/sh
X# To unshar, remove everything before the "cut here" line
X# and feed the result to /bin/sh
X'
X    }
X
X    print "sed -e 's/^X//' >$f <<'FUNKY_STUFF'\n";
X    print 'X', $_ while ( <FH> );
X    print "FUNKY_STUFF\n";
X    close(FH);
X}
X
X&Usage("No input files") unless $dirty;
Xexit(0);
FUNKY_STUFF

