#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

is(
scalar(`"$^X" -Ilib bin/nl -p -b ematch -n rz -s " " -v 10 t/data/nl/nl.txt`),
<<EOF
000010 body
000011 body
       header
000012 body
       body match
000013 body
       footer
EOF
,
"nl - number lines with various options"
);

