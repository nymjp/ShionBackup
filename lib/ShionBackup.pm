package ShionBackup;

our $VERSION = '0.01';

use warnings;
use strict;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::Temp qw( tempfile );

# ShionBackup modules
use ShionBackup::Logger;
use ShionBackup::Config;
use ShionBackup::PipeExec;
use ShionBackup::S3Uploader;

=head1 NAME

ShionBackup

=head1 CLASS METHODS

=over 4

=item run( @ARGV )

=cut

sub run {
    my $class = shift;
    local @ARGV = @_;

    my ($DUMP_CONFIG, $WORK_FILE);
    GetOptions(
        'help|h'       => \&usage,
        'dumpconfig|d' => \$DUMP_CONFIG,
        'workfile|w=s' => \$WORK_FILE,
        'debug' => sub { $ShionBackup::Logger::LOG_LEVEL = LOG_DEBUG },
    ) or usage();
    @ARGV || usage();

    my $conf = ShionBackup::Config->load(@ARGV);
    my $BUFF_SIZE;
    $BUFF_SIZE = $conf->{buffer} * 1000_000 if $conf->{buffer};

    if ($DUMP_CONFIG) {
        DEBUG "Mode: DUMP CONFIG";
        dump_config();
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

        my $s3up = $class->create_s3uploader($conf);

        for my $target ( @{ $conf->{targets} } ) {
            my $filename = $target->{filename};
            my $uploadsize
                = $target->{args}{UPLOAD_SIZE}
                ? $target->{args}{UPLOAD_SIZE} * 1000_000
                : undef;
            my $piper = ShionBackup::PipeExec->new;

            INFO "=======================";
            INFO "backup start: $filename";

            my $args = $target->{args};
            my $fh   = undef;
            for my $command ( @{ $target->{commands} } ) {
                next unless defined $command;
                $fh = $piper->run( $command, $fh, $args )
                    or die "piper error: $@";
            }
            die "no output error.\n" unless defined $fh;

            seek $work_fh, 0, 0;
            truncate $work_fh, 0;
            my ( $buffer, $is_part );
            my $size = 0;
            while (1) {

                #DEBUG "eof: ", eof $fh;
                # exit 99;
                $size += read( $fh, $buffer, 4096 ) or die "read error: $!";
                print $work_fh $buffer;

                if ( eof $fh ) {
                    eval {
                        $piper->check_status;
                    };
                    if ( $@ ) {
                        $s3up->abort_upload( $filename ) if $is_part;
                        die $@;
                    }

                    seek $work_fh, 0, 0;
                    if ( $is_part ) {
                        INFO "part uploading $filename: size=$size";
                        my $num = $s3up->upload_part( $filename, $work_fh );
                        INFO "part upload($num) done.";
                        INFO "finalizing upload $filename";
                        $s3up->complete_upload( $filename );
                        INFO "finalize done."
                    }
                    else {
                        INFO "uploading $filename: size=$size";
                        $s3up->upload( $filename, $work_fh );
                        INFO "upload done."
                    }
                    last;
                }
                elsif ( $uploadsize && $size >= $uploadsize ) {
                    if ( !$is_part ) {
                        INFO "initializing part upload $filename.";
                        $s3up->init_upload( $filename );
                        $is_part = 1;
                        INFO "initialize done."
                    }

                    seek $work_fh, 0, 0;
                    INFO "part uploading $filename: size=$size";
                    my $num = $s3up->upload_part( $filename, $work_fh );
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

=item create_s3uploader( \%config );

=cut

sub create_s3uploader {
    my $class = shift;
    my ($conf) = @_;

    my %s3conf = %{ $conf->{s3} };
    for ( @s3conf{ 'baseurl', 'id', 'secret' } ) {
        die "invalid s3 config.\n" unless defined $_;
        next unless ref $_ eq 'CODE';
        $_ = $_->();
    }

    ShionBackup::S3Uploader->new( $s3conf{baseurl}, $s3conf{id},
        $s3conf{secret} );
}

=back

=head1 FUNCTIONS

=over 4

=item usage

=cut

sub usage {
    pod2usage(
        -exitval  => 1,
        noperldoc => 1,
        verbose   => 2,
    );
}

=item dump_config

=cut

sub dump_config {
    print STDERR ShionBackup::Config->dump_config, "\n";
}

1;

=back

=cut

