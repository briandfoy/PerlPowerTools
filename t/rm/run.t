use strict;
use warnings;

use Test::More;

use File::Temp;
my $class = require './bin/rm';
is( $class, 'PerlPowerTools::rm' );


my $dir = File::Temp::tempdir( CLEANUP => 1 );
chdir $dir or BAIL_OUT( "Could not change to $dir: $!" );


# These are the elements in each row of the table
my $n; BEGIN { $n = 0 }
use constant FILES    => $n++;
use constant OPTIONS  => $n++;
use constant ARGS     => $n++;
use constant EXIT     => $n++;
use constant REMAINS  => $n++;
use constant WARNINGS => $n++;
use constant LABEL    => $n++;

unlink 't/x/y/bn/6/7/8/goo/txt/$$';
my $no_such_error = "$!";  # No such file
diag( "Missing file error text is <$no_such_error>" );

my @table = (
	[
		{},
		[qw(-f)],
		[qw(foo bar)],
		0,
		[qw()],
		[],
		"files don't exist, with -f"
	],
	[
		{},
		[],
		[qw(foo bar)],
		1,
		[qw()],
		[
		 qr/cannot remove 'foo': \Q$no_such_error\E/,
		 qr/cannot remove 'bar': \Q$no_such_error\E/,
		],
		"files don't exist"
	],
	[
		{
			foo => { mode => 0755, type => 'file' },
			bar => { mode => 0444, type => 'file' },
		},
		[],
		[qw(foo bar)],
		0,
		[qw()],
		[],
		"foo and bar"
	],
	[
		{
			foo => { mode => 0755, type => 'file' },
			bar => { mode => 0444, type => 'file' },
		},
		[],
		[qw(foo)],
		0,
		[qw(bar)],
		[],
		"foo but not bar"
	],
	[
		{
			'a'   => { mode => 0755, type => 'dir' },
			'a/b' => { mode => 0444, type => 'file' },
		},
		[],
		[qw(a)],
		1,
		[qw(a a/b)],
		[
			qr/'a': is a directory/,
		],
		"directory without -r or -R"
	],
	[
		{
			'a'   => { mode => 0755, type => 'dir' },
			'a/b' => { mode => 0444, type => 'file' },
		},
		[qw(-f)],
		[qw(a)],
		0,
		[qw(a a/b)],
		[],
		"directory without -r or -R, with -f"
	],
	[
		{
			'a'   => { mode => 0755, type => 'dir' },
			'a/b' => { mode => 0444, type => 'file' },
		},
		[],
		[qw(a/b)],
		0,
		[qw(a)],
		[],
		"file in a directory"
	],
	[
		{
			'a'   => { mode => 0755, type => 'dir' },
			'a/b' => { mode => 0444, type => 'file' },
		},
		[qw(-R)],
		[qw(a)],
		0,
		[],
		[],
		"recursive with -R"
	],
	[
		{
			'a'   => { mode => 0755, type => 'dir' },
			'a/b' => { mode => 0444, type => 'file' },
		},
		[qw(-r)],
		[qw(a)],
		0,
		[],
		[],
		"recursive with -r"
	],
	[
		{
			'a'   => { mode => 0755, type => 'file' },
		},
		[qw(-P)],
		[qw(a)],
		0,
		[],
		[qr/-P ignored/],
		"with -P"
	],

	);

subtest 'table' => sub {
	foreach my $row ( @table ) {
		my $label = $row->[LABEL];
		subtest $label => sub {
			my $spec = $row->[FILES];
			prepare_files( $spec );
			foreach my $file ( sort keys %{ $spec } ) {
				ok( -e $file, "$file exists as expected" );
				}

			my @run_args = ( @{ $row->[OPTIONS] }, @{ $row->[ARGS] } );

			my $error = '';
			open my $error_fh, '>:utf8', \$error;

			my $exit = do {
				no warnings qw(once redefine);
				local *PerlPowerTools::rm::exit = sub { return $_[1] };
				$class->run( args => \@run_args, error_fh => $error_fh );
				};
			is $exit, $row->[EXIT], "Exit code is " . $row->[EXIT];

			subtest 'what remains' => sub {
				pass() if @{ $row->[REMAINS] } == 0;
				foreach my $file ( @{ $row->[REMAINS] } ) {
					ok( -e $file, "$file exists after rm, as expected" );
					}
				};

			subtest 'warnings' => sub {
				if( @{ $row->[WARNINGS] } == 0 ) {
					is $error, '', 'There were no warnings';
					}
				else {
					foreach my $pattern ( @{ $row->[WARNINGS] } ) {
						like $error, $pattern, "Warnings match $pattern";
						}
					}
				};

			cleanup_files( $spec );
			};
		};
	};

done_testing();

sub prepare_files {
	my( $spec ) = @_;

	foreach my $key ( sort keys %$spec ) {
		if( $spec->{$key}{type} and $spec->{$key}{type} eq 'dir' ) {
			my $error = '';
			my @created = File::Path::make_path( $key, { mode => ($spec->{$key}{mode} || 0755), error => \$error } );
			}
		else {
			open my $fh, '>', $key or warn qq(Could not create file "$key": $!\n);
			print $fh $$;
			close $fh;
			}

		chmod $spec->{$key}{mode} if exists $spec->{$key}{mode};
		}
	}

sub cleanup_files {
	my( $spec ) = @_;

	foreach my $key ( sort keys %$spec ) {
		next unless -e $key; # as long as it's gone we don't care
		if( -d $key ) {
			eval { remove_tree $key };
			}
		else {
			chmod 0777, $key;
			unlink $key or warn "Could not unlink <$key>: $!\n";
			}

		chmod $spec->{$key}{mode} if exists $spec->{$key}{mode};
		}
	}
