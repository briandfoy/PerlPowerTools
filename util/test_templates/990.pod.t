#!/usr/bin/perl

use Test::Pod;

require './t/lib/common.pl';
my $program = program_name(__FILE__);

pod_file_ok( $program, "Valid POD in <$program>" );

end_testing();
