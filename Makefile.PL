use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ShionBackup',
    AUTHOR              => q{YAMAMOTO, N <nym@nym.jp>},
    VERSION_FROM        => 'lib/ShionBackup.pm',
    ABSTRACT_FROM       => 'lib/ShionBackup.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ShionBackup-*' },
);
