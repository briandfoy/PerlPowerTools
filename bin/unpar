#!/usr/bin/perl -w
#
# unpar - extract files from a Perl archive
#
# mail tgy@chocobo.org < bug_reports
#
# Copyright (c) 1999 Moogle Stuffy Software.  All rights reserved.
# You may play with this software in accordance with the Perl Artistic License.

my $VERSION = '0.02';

my %opts;
while (@ARGV && $ARGV[0] =~ s/^-//) {
    local $_ = shift;
    while (/([cdfqv])/g) {
        if ($1 eq 'd') {
            $opts{'d'} = /\G(.*)/g && $1 ? $1 : shift;
        } else {
            $opts{$1}++;
        }
    }
}

@ARGV = '-' unless @ARGV;

if ($opts{'v'}) {
    print "unpar $VERSION\n";
    exit;
}

my @files = map {
    local *F;
    open F, "< $_" or die "Couldn't open '$_': $!";
    *F;
} @ARGV;

if ($opts{'d'}) {
    chdir $opts{'d'} or die "Couldn't chdir '$opts{'d'}': $!";
}

local $SIG{__WARN__} = sub {} if $opts{'q'};

my $switch = $opts{'c'} || $opts{'f'} ? '-c' : '';

$/ = "\n__END__\n";

for my $file (@files) {
    while (<$file>) {
        s%.*^#!/usr/bin/perl$%%sm or next;
        local $ARGV[0] = $switch;
        eval;
        $@ and die $@;
    }
}

__END__

=head1 NAME

unpar - extract files from a Perl archive

=head1 SYNOPSIS

B<unpar> [-d dir] [-cfqv] file [files...]

=head1 DESCRIPTION

B<unpar> scans I<files> for Perl archives and extracts the files contained in
those archives.

=head1 OPTIONS

=over

=item -c

Overwrite existing files.

=item -d dir

Change directory to I<dir> before extracting files.

=item -f

Same as B<-c>.

=item -q

Shhh!

=item -v

Print version info and exit.

=back

=head1 SEE ALSO

B<par>

=head1 AUTHOR

Tim Gim Yee | tgy@chocobo.org | I want a moogle stuffy!

=head1 COPYRIGHT

Copyright (c) 1999 Moogle Stuffy Software.  All rights reserved.

You may play with this software in accordance with the Perl Artistic License.

=cut
