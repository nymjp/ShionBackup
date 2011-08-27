use strict;
use warnings;
use File::Spec::Functions qw(catfile);
use File::Basename;
use ExtUtils::MakeMaker;

unlink catfile( dirname(__FILE__), 'README.pod');
WriteMakefile(
    NAME                => 'ShionBackup',
    AUTHOR              => q{YAMAMOTO, N <nym@nym.jp>},
    VERSION_FROM        => 'lib/ShionBackup.pm',
    ABSTRACT            => 'Shion Backup Tool',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    EXE_FILES           => ['bin/shion-backup.pl'],
    MAN1PODS            => {},
    MAN3PODS            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ShionBackup-*' },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: par-bin shion-backup
par-bin: shion-backup
shion-backup: all
	pp -I $(INST_LIB) -o $@ -n -P $$(find $(INST_LIB) -name '*.pm' -printf '-M %P ') \
    $$(find bin -name '*.pl' -print)
MAKE_FRAG
}
