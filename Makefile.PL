use ExtUtils::MakeMaker 6.64;

my @exe_files = glob "bin/*";
my $main_file = 'lib/PerlPowerTools.pm';

WriteMakefile(
	'NAME'          => 'PerlPowerTools',
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'brian d foy <bdfoy@cpan.org>',

	'clean'         => { FILES => 'PerlPowerTools-*' },

	'EXE_FILES'     => \@exe_files,

	'PREREQ_PM'     => {
		'App::a2p'     => '0',
		'Make'         => '0',
		'MIME::Parser' => '0',
		'Curses'       => '0',
		'DB_File'      => '0',
		},

	'META_MERGE' => {
		"meta-spec" => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'git://github.com/briandfoy/PerlPowerTools.git',
				web  => 'https://github.com/briandfoy/PerlPowerTools',
				},

			bugtracker => {
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=PerlPowerTools',
				mailto => 'bug-PerlPowerTools@rt.cpan.org',
				},
			},
		},
	);

