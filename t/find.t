use strict;
use warnings;

use Test::More;

use Config;
use Data::Dumper;
use File::Basename;
use File::Path qw/ make_path /;
use File::Spec::Functions;
use File::Temp qw/ tempdir /;
use FindBin;

my $find2perl = catfile( dirname($Config{perlpath}), 'find2perl' )
    or die "Please install App::find2perl before continuing.\n";
diag( "find2perl is at <$find2perl>" );

subtest check_find2perl => sub {
	ok( -e $find2perl, "find2perl exists at $find2perl" );
	ok( -x $find2perl, "find2perl is executable $find2perl" );

	my $output = `$^X -c $find2perl 2>&1`;
	like( $output, qr/syntax OK/, "$find2perl compiles" );
	};

my $find = 'blib/script/find';
diag( "find is at <$find>" );

subtest check_find => sub {
	ok( -e $find, "find exists at $find" );
	ok( -x $find, "find is executable $find" );

	my $output = `$^X -c $find 2>&1`;
	like( $output, qr/syntax OK/, "$find compiles" );
	};

my $dir = tempdir('perlpowertools-find-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
ok(-d $dir, "Created temp dir: $dir");

{
my @file_paths = map catfile( $dir, $_ ), qw[
	a/b/c/20.txt
	d/40.txt
	e/f/60.txt
	g/h/i/80.txt
	];

my $files;
subtest create_files => sub {
	$files = create_files( @file_paths );
	diag( "Files are\n\t" . join( "\n\t", map { @$_ } @$files ) );
	};

sub show_times {
	foreach my $file ( @file_paths ) {
		diag sprintf "%s  a:%d  m:%d",
			$file,
			(stat $file)[8,9]
		}
	}

subtest 'all_files' => sub {
	show_times();
	my $options = "$dir -type f";
	my $command = "$^X $find $options";

	my $got = join "", sort `$command`;
	my $expected = join "\n", sort map { @$_ } @$files;
	$expected .= "\n";
	my $rc = is( $got, $expected, "Found files with `$command`" );

	unless( $rc ) {
		diag( "!!! Command: $command" );
		diag( "!!! Got:\n$got" );
		diag( "!!! Expected:\n\t", Dumper($files) );
		}
	};

my $i = 0;
foreach my $args ( [qw(amin -50)], [qw(mmin +50)] ) {
	subtest $args->[0] => sub { min_test( @$args, $files->[$i++] ) };
	}
}

done_testing();

sub create_files {
	my $pivot = 50;
	my @files;

	for my $file ( @_ ) {
		subtest "create_$file" => sub {
			my $path = dirname( $file );

			make_path($path);
			ok(-d $path, "Created path: $path");

			open my $fh, '>', $file; close $fh;
			ok(-e $file, "Created file: $file");

			my( $minutes ) = $file =~ /(\d+)\.txt$/;

			push @{ $files[$minutes > $pivot ? 1 : 0] }, $file;

			my $time = time - 60 * $minutes;
			ok( utime($time, $time, $file), "Set <$file> file time to $minutes minutes ago" );
			};
		}

	\@files;
	}

sub min_test {
	my( $arg, $time, $files ) = @_;
	show_times();

	my $options = "$dir -type f -$arg $time";
	my $command = "$^X $find $options";

	my $got = join '', sort `$command`;
	my $expected = join "\n", @$files, '';
	my $rc = is( $got, $expected, "Found files with `$command`" );

	unless( $rc ) {
		diag( "!!! Command: $command" );
		diag( "!!! Got:\n$got" );
		diag( "!!! Expected:\n\t", $expected );
		}
	}


__END__
