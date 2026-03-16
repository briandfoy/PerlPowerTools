use strict;
use warnings;

use Test::More 1;
use lib qw(lib);

my $class = 'PerlPowerTools::ls';
my $subclass;

subtest 'setup' => sub {
	my $class = require './bin_to_pack/ls';
	can_ok $class, qw(main);
	};

my( $output, $error );

BEGIN {
	package PerlPowerTools::ls::test;
	use vars qw(@ISA);
	our @ISA = qw(PerlPowerTools::ls);

	open my $output_fh, '>>', \$output;
	open my $error_fh,  '>>', \$error;

	sub exit         { return $_[1] }
	sub get_columns  { 137 }
	sub error_fh     { $error_fh }
	sub output_fh    { $output_fh }
	sub program_name { 'ls' }

	$subclass = __PACKAGE__;
	}

subtest 'version' => sub {
	my $method = 'VERSION_MESSAGE';

	my $instance = get_instance();
	can_ok $instance, $method;

	my $rc = $instance->$method;
	like $output, qr/ls version \d+\.\d+/, 'got expected version message';
	};

sub get_instance {
	my $instance;

	subtest 'make instance' => sub {
		$instance = $subclass->new;
		isa_ok $instance, $subclass;
		isa_ok $instance, $class;
		};

	return $instance;
	}

subtest 'process_options' => sub {
	my @good_options = split //, '1ACFLRSTWacdfgiklmnopqrstux';
                                 # 1ABCFGHILOPRSTUWabcdefghiklmnopqrstuvwxy%,

	subtest 'version' => sub {
		local @ARGV = qw(--version);
		my $rc = $subclass->run;
		like $output, qr/ls version \d+\.\d+/, 'expected version message';
		is $rc, 0, 'successful exit';
		};

	subtest 'good' => sub {
		my @table = (
			{
			label => 'one',
			args  => [ qw(-1 t) ],
			opts  => { 1 => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-f implies -a',
			args  => [ qw(-f t) ],
			opts  => { a => 1, f => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-l last over -1 -C -x',
			args  => [ qw(-1 -C -x -l t) ],
			opts  => { l => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-1 last over -l -C -x',
			args  => [ qw(-l -C -x -1 t) ],
			opts  => { 1 => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-x last over -1 -C -l',
			args  => [ qw(-1 -C -l -x t) ],
			opts  => { 'x' => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-C last over -1 -x -l',
			args  => [ qw(-1 -l -x -C t) ],
			opts  => { C => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-u wins over -c',
			args  => [ qw(-c -u t) ],
			opts  => { u => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-c wins over -u',
			args  => [ qw(-u -c t) ],
			opts  => { c => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-S wins over -t',
			args  => [ qw(-t -S t) ],
			opts  => { S => 1 },
			files => [ qw(t) ],
			},

			{
			label => '-t wins over -S',
			args  => [ qw(-S -t t) ],
			opts  => { t => 1 },
			files => [ qw(t) ],
			},

			map {
				my %h = (
					label => "-$_ single option",
					args  => [ "-$_", 't' ],
					opts  => { $_ => 1 },
					files => [ qw(t) ],
					);
				$h{opts}{a} = 1 if $_ eq 'f';
				\%h
				} @good_options

			);

		foreach my $h ( @table ) {
			subtest $h->{label} => sub {
				clear_output();

				local @ARGV = @{ $h->{args} };
				my $instance = get_instance();
				$instance->process_options;

				subtest options => sub {
					cmp_ok scalar keys %{ $h->{'opts'} }, '>', 0, 'there are expected keys';
					foreach my $key ( keys %{ $h->{'opts'} } ) {
						is $instance->options->{$key}, $h->{'opts'}{$key}, "$key matches";
						}
					};

				is_deeply $instance->arguments, $h->{files}, 'file list matches';
				};
			}
		};

	subtest 'bad' => sub {
		my @table = (
			{
				label => '-y',
				args  => [ qw( -y t ) ],
			},
			);

		foreach my $h ( @table ) {
			subtest $h->{label} => sub {
				clear_output();

				local @ARGV = @{ $h->{args} };
				my $instance = get_instance();
				$instance->process_options;

				like $error, qr/Unknown option: y/m, 'unknown option string';
				};
			}
		};
	};

sub clear_output {
	$output = '';
	$error  = '';
	}

done_testing();
