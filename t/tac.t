#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

sub _lines2re
{
    return join( qq#\r?\n#, @_ ) . qq#\r?\n?#;
}

sub test_tac
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($args) = @_;

    my @files = @{ $args->{files} };
    my @flags = @{ $args->{flags} };

    # die "@flags @files";
    my $re = _lines2re( @{ $args->{lines} } );
    return like( scalar(`$^X -Ilib bin/tac @flags @files`),
        qr#\A$re\z#ms, $args->{blurb} );
}

# TEST
test_tac(
    {
        blurb => "multiple files tac",
        files => [
            qw( t/data/sort/three-words.txt t/data/sort/ints1.txt t/data/sort/letters1.txt )
        ],
        flags => [qw/ /],
        lines => [ split /\n/, <<'EOF'],
column by pencil
row by row
mooing yodelling dog
mooing persistent cat
a little love
the meta protocol
based little mint
the wonderful unicorn
15
100
48
33
12
35
44
17
59
92
53
29
46
2
70
64
54
13
85
23
82
57
38
32
56
99
34
83
19
77
9
79
60
4
89
86
1
52
45
78
95
11
90
40
98
81
43
93
91
8
21
22
39
69
96
24
68
67
31
87
72
16
5
76
62
71
6
42
97
27
49
50
94
61
88
30
14
65
3
73
74
26
58
80
47
37
41
36
75
63
7
51
28
25
84
10
18
55
20
66
e
f
c
a
d
b
EOF
    }
);

# TEST
test_tac(
    {
        blurb => "-s flag",
        files => [qw( t/data/tac/a-sep.txt )],
        flags => [qw/ -s a /],
        lines => [ split /\n/, <<'EOF'],
threeatwoaonea
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
