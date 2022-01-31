#!/usr/bin/perl
use strict;
use warnings;

use Test::More 1;

subtest dash_u => sub {
	my $date = `$^X bin/date -u`;
	like $date, qr/\bUTC\b/;
	};

done_testing();
