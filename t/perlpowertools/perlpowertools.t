#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;;

is(
scalar(`"$^X" -Ilib bin/perlpowertools pwd`),
scalar($^O eq "MSWin32" ? `cd` : `pwd -P`),
"bin/perlpowertools pwd"
);
