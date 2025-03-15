use Test::More 1;

BEGIN {
	package Local::ls;
	our @ISA = qw(PerlPowerTools::ls);

	sub my_exit { $Local::ls::code   = $_[1] }

	sub my_warn { $Local::ls::error  .= $_[1] }

	sub output  { $Local::ls::output .= $_[1] }
	}

sub clear {
	$Local::ls::code   = undef;
	$Local::ls::error  = undef;
	$Local::ls::output = undef;
	}

my $class = 'Local::ls';

subtest 'setup' => sub {
	use lib qw(.);
	require_ok( 'bin/ls' );
	can_ok( $class, qw(run process_options) );
	};

subtest 'help' => sub {
	clear();
	my $method = 'VERSION_MESSAGE';
	can_ok $class, $method;
	$class->$method;
	like $Local::ls::output, qr/ls version \d+\.\d+/, 'git expected version message';
	};

subtest 'version' => sub {
	clear();
	my $method = 'VERSION_MESSAGE';
	can_ok $class, $method;
	$class->$method;
	like $Local::ls::output, qr/ls version \d+\.\d+/, 'git expected version message';
	};

subtest 'process_options' => sub {
	my @good_options = split //, '1ACFLRSTWacdfgiklmnopqrstux';
                                 # 1ABCFGHILOPRSTUWabcdefghiklmnopqrstuvwxy%,
	my $method = 'process_options';
	can_ok $class, $method;

	subtest 'version' => sub {
		clear();
		$class->$method( qw(--version) );
		like $Local::ls::output, qr/ls version \d+\.\d+/, 'git expected version message';
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
				my( $opts, @files ) = $class->$method( @{ $h->{args} } );
				is_deeply $opts,   $h->{opts}, 'options hash matches' or diag explain $opts;
				is_deeply \@files, $h->{files}, 'file list matches' or diag explain \@files;
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
				clear();
				my $w;
				local $SIG{__WARN__} = sub { $Local::ls::error .= $_[0] };
				$class->$method( @{ $h->{args} } );
				like $Local::ls::error, qr/^Unknown option: y/m, 'unknown option string';
				like $Local::ls::error, qr/^usage: /m, 'usage message';
				is $Local::ls::code, 1, 'exit code is expected';
				};
			}
		};
	};


done_testing();
