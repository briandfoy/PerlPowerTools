#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IPC::Run3 qw(run3);

sub test_sort {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my( $args ) = @_;

	subtest $args->{blurb} => sub {
		run3(
			[ $^X, 'bin/sort', @{$args->{flags}}, @{$args->{files}} ],
			undef, \my @output
			);
		is( $? >> 8, 0, 'Successful exit code' );

		@output = map { s/[\r\n]+//; $_ } @output;

		is_deeply( \@output, $args->{lines}, "Output for <$args->{blurb}> is sorted" );
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


subtest sort_stdin => sub {
	$ENV{TMPDIR} ||= '.';
	my @letters = qw(a b c d);
	my $input = join "\n", reverse qw(a b c d);

	run3(
		[$^X, 'bin/sort', '-' ],
		\$input, \my @output, \my $error
		);

	@output = map { s/[\r\n]+//; $_ } @output;

	is_deeply( \@letters, \@output );
	};


subtest is_sorted => sub {
	$ENV{TMPDIR} ||= '.';
	my @letters = qw(a b c d);
	my $input = join "\n", qw(a b c d);

	run3(
		[$^X, 'bin/sort', '-c', '-' ],
		\$input, \my @output, \my $error
		);

	is( $? >> 8, 0, "sorted list exits with 0" );
	};

subtest is_not_sorted => sub {
	$ENV{TMPDIR} ||= '.';
	my @letters = qw(a b c d);
	my $input = join "\n", qw(b a d);

	run3(
		[$^X, 'bin/sort', '-c', '-' ],
		\$input, \my @output, \my $error
		);

	is( $? >> 8, 1, "unsorted list exits with 1" );
	};

done_testing();

=head1 COPYRIGHT & LICENSE

Portions Copyright 2018 by Shlomi Fish

This code is licensed under the Artistic License 2.0
L<https://opensource.org/licenses/Artistic-2.0>, or at your option any later
version of the Artistic License from TPF ( L<https://www.perlfoundation.org/> )
.
