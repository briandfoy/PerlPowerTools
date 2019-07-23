use strict;
use warnings;

use Test::More;

use Data::Dumper;
use File::Basename;
use File::Path qw/ make_path /;
use File::Spec::Functions;
use File::Temp qw/ tempdir /;

my $dir = tempdir('ppt-find-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
ok(-d $dir, "Created temp dir: $dir");

{
my @files = map catfile( $dir, $_ ), qw[
	a/b/c/20.txt
	d/40.txt
	e/f/60.txt
	g/h/i/80.txt
	];

my $found = create_files( @files );

my $i = 0;
foreach my $args ( [qw(amin -50)], [qw(mmin +50)] ) {
	subtest $args->[0] => sub { min_test( @$args, $found->[$i++] ) };
	}
}

done_testing();

sub create_files {
	my $pivot = 50;
	my @found;

	for my $file ( @_ ) {
		my $path = dirname( $file );

		make_path($path);
		ok(-d $path, "Created path: $path");

		open my $fh, '>', $file; close $fh;
		ok(-e $file, "Created file: $file");

		my( $minutes ) = $file =~ /(\d+)\.txt$/;

		push @{ $found[$minutes > $pivot ? 1 : 0] }, $file;

		my $time = time - 60 * $minutes;
		ok( utime($time, $time, $file), "Set <$file> file time to $minutes minutes ago" );
		}

	\@found;
	}

sub min_test {
	my( $arg, $time, $found ) = @_;

	my $options = "$dir -type f -$arg $time";
	my $command = "$^X bin/find $options";

	my $got = join '', sort `$command`;
	my $expected = join "\n", @$found, '';
	my $rc = is( $got, $expected, "Found files with `$command`" );

	unless( $rc ) {
		diag( "!!! Command: $command" );
		diag( "!!! Got:\n$got" );
		diag( "!!! Found:\n\t", Dumper($found) );
		}
	}


__END__
