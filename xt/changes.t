use Test::More;
eval 'use Test::CPAN::Changes 0.500005';
plan skip_all => 'Test::CPAN::Changes 0.500005 required for this test' if $@;
changes_ok();
