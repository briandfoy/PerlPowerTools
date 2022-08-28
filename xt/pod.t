use strict;
use warnings;

use Test::More;

eval "use Test::Pod 1.49"
	or plan( skip_all => 'Test::Pod 1.49 required for testing POD.' );

all_pod_files_ok();
