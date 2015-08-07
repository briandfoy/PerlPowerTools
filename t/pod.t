use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);


if ( not $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => 'Pod coverage tests are not active. Please set $ENV{AUTHOR_TESTING} to activate.' );
}

eval "use Test::Pod 1.49";

if ( $EVAL_ERROR ) {
    print $EVAL_ERROR;
    plan( skip_all => 'Test::Pod 1.49 required for testing POD.' );
}

all_pod_files_ok();
