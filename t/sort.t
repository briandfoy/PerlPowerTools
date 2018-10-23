#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

{
    # TEST
    like(
        scalar(`$^X -Ilib bin/sort t/data/sort/letters1.txt`),
        qr#\Aa\r?\nb\r?\nc\r?\nd\r?\ne\r?\nf\r?\n?\z#ms,
        "letters sort"
    );
    my $ints_re = join( qq#\r?\n#, 1 .. 100 );

    # TEST
    like( scalar(`$^X -Ilib bin/sort -n t/data/sort/ints1.txt`),
        qr#\A$ints_re\r?\n?\z#ms, "integers sort" );
}

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
