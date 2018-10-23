#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

sub _lines2re
{
    return join( qq#\r?\n#, @_ ) . qq#\r?\n?#;
}

{
    my $letters_re = _lines2re(qw/ a b c d e f /);

    # TEST
    like( scalar(`$^X -Ilib bin/sort t/data/sort/letters1.txt`),
        qr#\A$letters_re\z#ms, "letters sort" );
}

{
    my $ints_re = _lines2re( 1 .. 100 );

    # TEST
    like( scalar(`$^X -Ilib bin/sort -n t/data/sort/ints1.txt`),
        qr#\A$ints_re\z#ms, "integers sort" );
}

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
