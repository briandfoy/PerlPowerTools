#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

sub _lines2re
{
    return join( qq#\r?\n#, @_ ) . qq#\r?\n?#;
}

sub test_sort
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($args) = @_;

    my $re = _lines2re( @{ $args->{lines} } );
    return like(
        scalar(`"$^X" -Ilib bin/sort @{$args->{flags}} @{$args->{files}}`),
        qr#\A$re\z#ms, $args->{blurb} );
}

# TEST
test_sort(
    {
        blurb => "letters sort",
        files => [qw( t/data/sort/letters1.txt )],
        flags => [],
        lines => [qw/ a b c d e f /],
    }
);

# TEST
test_sort(
    {
        blurb => "integers sort",
        files => [qw( t/data/sort/ints1.txt )],
        flags => [qw/ -n /],
        lines => [ 1 .. 100 ],
    }
);

# TEST
test_sort(
    {
        blurb => "multiple -k sort",
        files => [qw( t/data/sort/three-words.txt )],
        flags => [qw/ -k 2 -k 1 /],
        lines => [ split /\n/, <<'EOF'],
column by pencil
row by row
a little love
based little mint
the meta protocol
mooing persistent cat
the wonderful unicorn
mooing yodelling dog
EOF
    }
);

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
