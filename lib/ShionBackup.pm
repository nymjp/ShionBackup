package ShionBackup;

our $VERSION = '0.01';

use warnings;
use strict;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::Temp qw( tempfile );

# ShionBackup modules
use ShionBackup::Logger qw(:all);
use ShionBackup::Config;
use ShionBackup::TargetProcesser;
use ShionBackup::Uploader;

our $USAGE = undef;

=head1 NAME

ShionBackup

=head1 CLASS METHODS

=over 4

=item run( @ARGV )

=cut

sub run {
    my $class = shift;
    local @ARGV = @_;
    set_log_level(LOG_INFO);    # default log level

    my ( $DUMP_TARGET, $DUMP_CONFIG, $WORK_FILE, $NOUPLOAD, $PROGRESS );
    GetOptions(
        'help|h'             => \&usage,
        'dump-target|dump|d' => \$DUMP_TARGET,
        'dump-config'        => \$DUMP_CONFIG,
        'workfile|w=s'       => \$WORK_FILE,
        'noupload'           => \$NOUPLOAD,
        'progress'           => \$PROGRESS,
        'trace'              => sub { set_log_level(LOG_TRACE) },
        'debug'              => sub { set_log_level(LOG_DEBUG) },
    ) or usage();
    @ARGV || usage();

    my $conf = ShionBackup::Config->new;
    $conf->load(@ARGV);

    if ($DUMP_CONFIG) {
        DEBUG "Mode: DUMP CONFIG";
        print $conf->dump_raw();
        $conf->process;
        exit 0;
    }

    $conf->process;
    if ($DUMP_TARGET) {
        DEBUG "Mode: DUMP TARGET";
        print $conf->dump_target();
        exit 0;
    }
    else {
        DEBUG "Mode: BACKUP";

        my $uploader = $class->create_uploader( $conf->uploader, $NOUPLOAD,
            $PROGRESS );

        ## abort previous incomplete upload
        $uploader->abort_incomplete;

        my $tp = ShionBackup::TargetProcesser->new( $uploader, $WORK_FILE );
        for my $target ( @{ $conf->target->all } ) {
            $tp->run($target);
        }
    }
    INFO 'all backup end';
}

=item create_uploader( Config::Uploader $config, $noupload, $progress );

=cut

sub create_uploader {
    my $class = shift;
    my ( $conf, $noupload, $progress ) = @_;

    if ($noupload) {
        INFO "*** noupload ***";
        $conf->set_class('Null');
    }

    my $uploader = ShionBackup::Uploader->create($conf);
    TRACE "uploader: ", ref $uploader if IS_TRACE;
    $uploader->set_show_progress(1) if ($progress);
    $uploader;
}

=back

=head1 FUNCTIONS

=over 4

=item usage

=cut

sub usage {
    pod2usage(
        -exitval => 2,

        #-noperldoc => 1,
        -verbose => 2,
        -input   => $USAGE,
        -output  => \*STDOUT,
    );
}

=item dump_config

=cut

sub dump_config {
    print STDERR ShionBackup::Config->dump_config, "\n";
}

=item dump_target

=cut

sub dump_target {
    print STDERR ShionBackup::Config->dump_target, "\n";
}

1;

=back

=cut

