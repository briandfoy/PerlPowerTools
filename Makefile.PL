my $bin = 'bin';
opendir BIN, $bin or die $!;
my @exe_files = map "$bin/$_", grep { $_ !~ /^\./ } readdir BIN;
closedir BIN;

use ExtUtils::MakeMaker;
WriteMakefile(
              VERSION_FROM => 'README',
              PREFIX       => '/usr/local/ppt',
              NAME         => 'ppt',
              EXE_FILES    => \@exe_files,
);