#!perl
use v5.10;

use Mojo::UserAgent;
use Mojo::Util qw(dumper);

my $ua = Mojo::UserAgent->new;
my $url = 'https://ss64.com/nt/timezones.html';

my %hash = Mojo::UserAgent
	->new
	->get( $url )
	->result
	->dom
	->find( 'table#rowhover > tr' )
	->map( sub { ($_->find( 'td' )->map( 'all_text' )->each)[2,4] } )
	->each;

say dumper( \%hash );
