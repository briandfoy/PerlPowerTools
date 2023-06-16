#!/usr/bin/perl
use strict;
use warnings;

use JSON qw(decode_json);
use Test::More;

require './t/lib/common.pl';

my $program = program_name();
ok -e $program, "$program exists";

my $output = `"$^X" util/extract_metadata $program`;
my $json = decode_json( $output );

subtest "required keys" => sub {
	my $this = $json->{$program};
	my @keys = qw(Name Description Author License);

	ok( exists $this->{$_}, "has $_ key" ) for @keys;
	};

done_testing();

__END__
