use strict;
use warnings;
use lib qw(lib);

use Test::More;

my $class = require './bin_to_pack/rm';

is $class, 'PerlPowerTools::rm';

my $subclass;
{
package PerlPowerTools::rm::test;
use vars qw(@ISA);
@ISA = ($class);

my $error;
open my $error_fh, '>>', \$error;
sub error_fh { $error_fh }

$subclass = __PACKAGE__;
}

subtest process_options => sub {
	my $method = 'process_options';
	can_ok $class, 'new', 'options', $method;

	my @table = (
		[ [ qw(a b c        ) ],   {},           [qw(a b c)] ],
		[ [ qw(-- a b c     ) ],   {},           [qw(a b c)] ],
		[ [ qw(-iv a b c    ) ],   {i=>1, v=>1}, [qw(a b c)] ],
		[ [ qw(-f 1 2 3     ) ],   {f=>1      }, [qw(1 2 3)] ],

		[ [ qw(-iR -P       ) ],   {i=>1, P=>1, R=>1}, [qw()         ] ],
		[ [ qw(-ir -P       ) ],   {i=>1, P=>1, r=>1}, [qw()         ] ],
		[ [ qw(-iR -P foo b ) ],   {i=>1, P=>1, R=>1}, [qw(foo b)    ] ],
		[ [ qw(-ir -P f bar ) ],   {i=>1, P=>1, r=>1}, [qw(f bar)    ] ],

		[ [ qw( -i -f -- -i ) ],   {f=>1            }, [qw( -i ) ] ],
		[ [ qw( -f -i -- -f ) ],   {i=>1            }, [qw( -f ) ] ],
		[ [ qw( -if         ) ],   {f=>1            }, [qw(    ) ] ],
		[ [ qw( -fi         ) ],   {i=>1            }, [qw(    ) ] ],
		);

	my %defaults = map { $_ => undef } qw(i f R r P v);
	foreach my $row ( @table ) {
		local @ARGV = @{ $row->[0] };
		my $instance = $subclass->new->$method();

		$instance->preprocess_options;
		$instance->process_options;
		$instance->postprocess_options;

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
			is !! $instance->is_recursive,   !! (!!$row->[1]{R} + !!$row->[1]{r}), 'is_recursive has expected value';
			is !! $instance->is_verbose,     !! $row->[1]{v}, 'is_verbose has expected value';
			};
		}

	};

done_testing();
