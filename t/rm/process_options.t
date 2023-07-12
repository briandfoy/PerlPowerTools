use strict;
use warnings;

use Test::More;

my $class = require './bin/rm';

is( $class, 'PerlPowerTools::rm' );

subtest preprocess_options => sub {
	my $method = 'preprocess_options';
	can_ok $class, 'new', 'options', $method;

	my @table = (
		[ [ qw(a b c        ) ],  [ qw( a b c        ) ] ],
		[ [ qw(-- a b c     ) ],  [ qw(-- a b c      ) ] ],
		[ [ qw(-abc         ) ],  [ qw(-a -b -c      ) ] ],
		[ [ qw(-a -bc       ) ],  [ qw(-a -b -c      ) ] ],
		[ [ qw(-ab -c       ) ],  [ qw(-a -b -c      ) ] ],
		[ [ qw(-ab -- -c    ) ],  [ qw(-a -b -- -c   ) ] ],
		[ [ qw(-ab -- -c    ) ],  [ qw(-a -b -- -c   ) ] ],
		[ [ qw(-ab -- -abc  ) ],  [ qw(-a -b -- -abc ) ] ],
		[ [ qw( -i -f       ) ],  [ qw( -f           ) ] ],
		[ [ qw( -f -i       ) ],  [ qw( -i           ) ] ],
		[ [ qw( -i -f -- -i ) ],  [ qw( -f -- -i     ) ] ],
		[ [ qw( -f -i -- -f ) ],  [ qw( -i -- -f     ) ] ],
		);

	foreach my $row ( @table ) {
		my $instance = $class->new( args => $row->[0] )->$method();
		isa_ok $instance, $class;
		is_deeply $instance->{preprocessed_args}, $row->[1],
			qq(preprocessed_args match for <@{$row->[0]}> -> <@{$row->[1]}>);
		}
	};

subtest process_options => sub {
	my $method = 'process_options';
	can_ok $class, 'new', 'options', $method;

	my @table = (
		[ [ qw(a b c        ) ],   {},           [qw(a b c)] ],
		[ [ qw(-- a b c     ) ],   {},           [qw(a b c)] ],
		[ [ qw(-iv a b c    ) ],   {i=>1, v=>1}, [qw(a b c)] ],
		[ [ qw(-f 1 2 3     ) ],   {f=>1      }, [qw(1 2 3)] ],

		[ [ qw(-iR -P       ) ],   {i=>1, P=>1, R=>1}, [qw()         ] ],
		[ [ qw(-ir -P       ) ],   {i=>1, P=>1, R=>1}, [qw()         ] ],
		[ [ qw(-iR -P foo b ) ],   {i=>1, P=>1, R=>1}, [qw(foo b)    ] ],
		[ [ qw(-ir -P f bar ) ],   {i=>1, P=>1, R=>1}, [qw(f bar)    ] ],
		[ [ qw( -i -f -- -i ) ],   {f=>1            }, [qw( -i     ) ] ],
		[ [ qw( -f -i -- -f ) ],   {i=>1            }, [qw( -f     ) ] ],
		);

	my %defaults = map { $_ => 0 } qw(i f R r P v);
	foreach my $row ( @table ) {
		my $instance = $class->new( args => $row->[0] )->$method();
		isa_ok $instance, $class;
		my $options = { %defaults, %{ $row->[1] } };
		is_deeply $instance->options, $options,
			qq(Options match for <@{$row->[0]}>);
		is_deeply [$instance->files], $row->[2],
			qq(Files match for <@{$row->[0]}> -> <@{$row->[2]}>);

		subtest option_queries => sub {
			is !! $instance->is_force,       !! $row->[1]{f}, 'is_force has expected value';
			is !! $instance->is_interactive, !! $row->[1]{i}, 'is_interactive has expected value';
			is !! $instance->is_overwrite,   !! $row->[1]{P}, 'is_overwrite has expected value';
			is !! $instance->is_recursive,   !! $row->[1]{R}, 'is_recursive has expected value';
			is !! $instance->is_verbose,     !! $row->[1]{v}, 'is_verbose has expected value';
			};
		}

	};

done_testing();
