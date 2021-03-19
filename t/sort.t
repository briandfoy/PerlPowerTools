#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IPC::Open3 qw(open3);

sub test_sort {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my( $args ) = @_;

	subtest $args->{blurb} => sub {
		my $pid = open3( my $in, my $out, my $err,
			$^X, 'bin/sort', @{$args->{flags}}, @{$args->{files}}
			);
		ok( $pid > 0, "open3 opened" );

		close $in;
		my @output = map { s/\R// } <$out>;

		is_deeply( \@output, $args->{lines}, "Output is sorted" );
		};
	}

test_sort(
    {
        blurb => "letters sort",
        files => [qw( t/data/sort/letters1.txt )],
        flags => [],
        lines => [qw/ a b c d e f /],
    }
);

test_sort(
    {
        blurb => "integers sort",
        files => [qw( t/data/sort/ints1.txt )],
        flags => [qw/ -n /],
        lines => [ 1 .. 100 ],
    }
);

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

done_testing();

__END__

subtest sort_stdin => sub {
	my $pid = open3( my $in, my $out, my $err,
		$^X, 'bin/sort', '-'
		);
	ok( $pid > 0, "open3 opened" );

	my @letters = qw(a b c d);
	foreach my $i ( reverse @letters ) {
		print {$in} "$i\n";
		}
	close $in;

	chomp( my @output = <$out> );
	close $out;

	is_deeply( \@letters, \@output );
	};

subtest is_sorted => sub {
	open my $p, '|-', qq("$^X" bin/sort -c);
	foreach my $i ( qw( a b c d ) ) {
		print {$p} "$i\n";
		}
	close $p;
	my $exit = $? >> 8;
	is( $exit, 0, 'sort -c exits with 0 for sorted input' );
	};

subtest is_not_sorted => sub {
	open my $p, '|-', qq("$^X" bin/sort -c);
	foreach my $i ( qw( b a d ) ) {
		print {$p} "$i\n";
		}
	close $p;
	my $exit = $? >> 8;
	is( $exit, 1, 'sort -c exits with 0 for unsorted input' );
	};


=head1 COPYRIGHT & LICENSE

Portions Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
