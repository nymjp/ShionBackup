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
use ShionBackup::PipeExec;
use ShionBackup::Uploader;
use ShionBackup::Util;

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
        my $work_fh;
        if ($WORK_FILE) {
            open $work_fh, '+>', $WORK_FILE or die $!;
        }
        else {
            $work_fh = tempfile( UNLINK => 1 );
        }

        my $uploader = $class->create_uploader( $conf->uploader, $NOUPLOAD,
            $PROGRESS );

        ## abort previous incomplete upload
        $uploader->abort_incomplete;

        for my $target ( @{ $conf->target->all } ) {
            my $filename   = $target->filename;
            my $uploadsize = $target->uploadsize_byte;
            my $piper      = ShionBackup::PipeExec->new;

            INFO "=======================";
            INFO "backup start: $filename";

            my $args = $target->arg;
            my $fh   = undef;
            for my $command ( @{ $target->command_array } ) {
                next unless defined $command;
                $fh = $piper->run( $command, $fh, $args )
                    or die "piper error: $@";
            }
            die "no output error.\n" unless defined $fh;

            seek $work_fh, 0, 0;
            truncate $work_fh, 0;
            my ( $buffer, $part_context );
            my $size = 0;
            while (1) {

                #DEBUG "eof: ", eof $fh;
                # exit 99;
                $size += read( $fh, $buffer, 4096 ) or die "read error: $!";
                print $work_fh $buffer;

                if ( eof $fh ) {
                    eval { $piper->check_status; };
                    if ($@) {
                        $uploader->abort_upload( $part_context, $filename )
                            if $part_context;
                        die $@;
                    }

                    seek $work_fh, 0, 0;
                    if ($part_context) {
                        INFO "part uploading $filename: size=",
                            commify($size);
                        my $num = $uploader->upload_part( $part_context,
                            $filename, $work_fh );
                        INFO "part upload($num) done.";
                        INFO "finalizing upload $filename";
                        $uploader->complete_upload( $part_context,
                            $filename );
                        INFO "finalize done.";
                    }
                    else {
                        INFO "uploading $filename: size=", commify($size);
                        $uploader->upload( $args, $filename, $work_fh );
                        INFO "upload done.";
                    }
                    last;
                }
                elsif ( $uploadsize && $size >= $uploadsize ) {
                    if ( !$part_context ) {
                        INFO "initializing part upload $filename.";
                        $part_context
                            = $uploader->init_upload( $args, $filename );
                        INFO "initialize done.";
                    }

                    seek $work_fh, 0, 0;
                    INFO "part uploading $filename: size=", commify($size);
                    my $num
                        = $uploader->upload_part( $part_context, $filename,
                        $work_fh );
                    INFO "part upload($num) done.";

                    seek $work_fh, 0, 0;
                    truncate $work_fh, 0;
                    $size = 0;
                }
            }
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
        -exitval   => 2,
        #-noperldoc => 1,
        -verbose   => 2,
        -input     => $USAGE,
        -output    => \*STDOUT,
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

