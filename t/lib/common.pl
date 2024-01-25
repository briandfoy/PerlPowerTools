use strict;
use warnings;

use File::Basename qw(basename dirname);
use File::Spec::Functions qw(catfile);

use Test::More;
use Test::Warnings qw(had_no_warnings);

=head1 NAME


=head1 SYNOPSIS


=head1 DESCRIPTION

=head2 Functions

=over

=item * dumper

=cut

# Stolen from Mojo::Util
use Data::Dumper;
sub dumper { Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump }

=item * extract_meta( PROGRAM )

Extracts the metadata as a hash reference of the named PROGRAM
(e.g. 'bin/false')

=cut

sub extract_meta {
	my( $program ) = @_;

	open my $fh, '<:utf8', $program or do {
		warn "Could not open <$program>: $!\n";
		return;
		};
	my $data = do { local $/; <$fh> };

	my( $extracted ) = $data =~ m/
		^=begin \s+ metadata \s+
			(.+)
		^=end \s+ metadata
		/xms;

	my %hash;
	foreach my $line ( split /[\n\r]/, $extracted ) {
		my( $field, $value ) = split /:\s*/, $line, 2;
		if( exists $hash{$field} and ! ref $hash{$field} ) {
			$hash{$field} = [ $hash{$field}, $value ];
			}
		else {
			$hash{$field} = $value;
			}
		}

	if( exists $hash{'Author'} and ! ref $hash{'Author'} ) {
		$hash{'Author'} = [ $hash{'Author'} ]
		}

	\%hash;
	}

sub program_name {
	my( $file ) = defined $_[0] ? $_[0] : (caller(0))[1];
	catfile 'bin', basename( dirname( $file ) );
	}

sub programs_to_test {
	if( exists $ENV{PERLPOWERTOOLS_PROGRAMS} ) {
		map { m|\Abin| ? $_: catfile( 'bin', $_ ) } split /\s*,\s*/, $ENV{PERLPOWERTOOLS_PROGRAMS};
		}
	else {
		my %Excludes = map { catfile( 'bin', $_ ), 1 } qw(perlpowertools perldoc);
		my @programs = grep { ! exists $Excludes{$_} } glob( 'bin/*' );
		}
	}

use IPC::Run3 qw(run3);
sub run_command {
	my( $program, $args, $input ) = @_;

	run3(
		[$^X, $program, @$args ],
		\$input, \my $output, \my $error
		);

	my %result;
	@result{qw( program args stdout stderr exit)} = ( $program, [@$args], $output, $error, $? >> 8 );
	return \%result;
	}

sub run_program_test {
	my( $label, $sub ) = @_;

	foreach my $program ( programs_to_test() ) {
		no strict 'refs';
		my @args = ($program);

		subtest "$label - $program" => sub {
			my( $override_file ) =
				grep { m/ \/ ([0-9]+\.) \Q$label\E \.t \z/x }
				glob( catfile( 't', basename($program), '*.t' ) );

			if( defined $override_file and -e $override_file ) {
				diag( "Found $program specific override file" );
				eval { use lib qw(.); require $override_file }
					or fail ( "Could not run override file $override_file: $@" );
				}
			elsif( ref $sub eq ref sub {} ) {
				eval { $sub->(@args) }
					or fail( "Failure running code ref test: $@" );
				}
			elsif( defined &{$sub} ) {
				eval { &{$sub}(@args) }
					or fail( qq(Failure running test named "$sub": $@) );
				}
			else {
				fail( "Tried to run $sub but that's not a defined test name" );
				}
			}
		};
	}

=back

=head2 Pre-defined tests

=over

=item * compile_test

=cut

sub compile_test {
	my( $program ) = @_;

	subtest compile => sub {
		return fail( "Program <$program> exists" )
			unless -e $program;
		my $output = `"$^X" -c "$program" 2>&1`;
		like $output, qr/syntax OK/, "$program compiles"
			or diag( $output );
		};
	}

=item * sanity_test

=cut

sub sanity_test {
	my( $program ) = @_;

	my $rc = subtest "$program sanity test" => sub {
		ok -e $program, "$program exists";
		compile_test($program);
		};

	unless($rc) {
		done_testing();
		note "No sense continuing after sanity tests fail\n";
		CORE::exit 255;
		}

	$rc;
	}

=back

=cut

1;
