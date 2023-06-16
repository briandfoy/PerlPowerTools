#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

sub _lines2re
{
    return join( qq#\r?\n#, @_ ) . qq#\r?\n?#;
}

sub test_cat
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($args) = @_;

    my $re = _lines2re( @{ $args->{lines} } );
    return like(
        scalar(`"$^X" -Ilib bin/cat @{$args->{flags}} @{$args->{files}}`),
        qr#\A$re\z#ms, $args->{blurb} );
}

# TEST
test_cat(
    {
        blurb => "format string expansion in cat -n",
        files => [qw( t/data/cat/cat-n-1.txt )],
        flags => [qw( -n )],
        lines => ["     1  %d"],
    }
);

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
