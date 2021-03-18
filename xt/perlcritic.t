use Test::More 0.94;
use Test::Perl::Critic ( -profile => 'xt/perlcriticrc' );

all_critic_ok( 'bin' );
