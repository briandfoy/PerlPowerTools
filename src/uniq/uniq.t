#!/usr/local/bin/perl5
# test suite for uniq
# run as: ./uniq.t
# uniq.t.dat must be in @INC;

$| = 1;
require "uniq.t.dat";

my $program = "./uniq";
my $output_tmp = "/tmp/uniq.output_tmp";
my $in = "/tmp/uniq.in";
my $out = "/tmp/uniq.out";

LOOP: foreach(@tests) {
	my($name, $opts) = split /\s*~\s*/;
	my $test = "test_$name";
	defined @$test or die "no tests for $name\n";
	print "testing $name: $program $opts\n";
	foreach(@$test) {
		my($input, $output) = split /~/;
		create_files([$in, $input], [$out, $output]);
		my $cmd = "$program $opts $in $output_tmp";
		print "$cmd   ";
		my $err = system $cmd;
		my @diff = `diff $out $output_tmp`;
		if($err || @diff) {
			print "NOT OK ($_)\n", map "    $_", @diff;
			last LOOP;
		}
		else {
			print "OK\n";
		}
	}
	print "\n";
	unlink $in, $out, $output_tmp;
}

sub create_files {
	my(@data) = @_;
	foreach my $elem (@data) {
		my($file, $lines) = @$elem;
		open F, ">$file"
			or die "couldn't open >$file: $!\n";
		foreach my $line (split /,/, $lines) {
			print F eval "\"$line\"", "\n";
		}
		close F;
	}
}
