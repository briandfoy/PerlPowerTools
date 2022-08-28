use Test::More 0.94;
eval q(
	use Test::Perl::Critic ( -profile => 'xt/perlcriticrc' )
	);
plan( skip_all => 'Test::Perl::Critic needed for this test' ) if $@;

all_critic_ok( 'bin' );
