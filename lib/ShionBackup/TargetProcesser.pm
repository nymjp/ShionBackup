package ShionBackup::TargetProcesser;

=head1 NAME

ShionBackup::TargetProcesser

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use File::Temp;
use ShionBackup::Logger qw(:all);
use ShionBackup::Config;
use ShionBackup::Util;
use ShionBackup::PipeExec;
use ShionBackup::Uploader;

our $READ_UNIT = 4096;

=head2 CONSTRUCTOR

=over 4

=item new( Uploader $uploader, [ $workfilename ] )

=cut

sub new {
    my $class = shift;
    my ( $uploader, $workfile ) = @_;

    my $work_fh;
    if ($workfile) {
        open $work_fh, '+>', $workfile or die $!;
    }
    else {
        $work_fh = File::Temp->new( UNLINK => 1 );
        TRACE "workfile: ", $work_fh->filename if IS_TRACE;
    }

    bless {
        uploader => $uploader,
        work_fh  => $work_fh,
    }, $class;
}

=back

=head2 D/A METHODS

=over 4

=item uploader, set_uploader

=cut

for my $field ( qw[ uploader ] ) {
    my $slot_get = __PACKAGE__ . "::$field";
    my $slot_set = __PACKAGE__ . "::set_$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;
        $self->{$field};
    };
    *$slot_set = sub {
        my $self = shift;
        $self->{$field} = shift;
    };
}

=back

=head2 METHODS

=over 4

=item run( Config::Target $target ) : $size

=cut

sub run {
    my $self = shift;
    my ($target) = @_;

    my $filename = $target->filename;

    INFO "=======================";
    INFO "backup start: $filename";

    my $piper = $self->spawn_commands($target);
    $self->process_output( $piper, $target );
}

=item spawn_commands( Config::Target $target ) : PipeExec

=cut

sub spawn_commands {
    my $self = shift;
    my ($target) = @_;

    my $piper = $self->_create_piper;
    my $args  = $target->arg;
    for my $command ( @{ $target->command_array } ) {
        next unless defined $command;
        $piper->run( $command, $args );
    }
    die "no output error.\n" unless defined $piper->output_fh;
    $piper;
}

=item process_output( PipeExec $piper, Config::Target $target ) : $size

=cut

sub process_output {
    my $self = shift;
    my ( $piper, $target ) = @_;

    my $fh         = $piper->output_fh;
    my $filename   = $target->filename;
    my $args       = $target->arg;
    my $uploadsize = $target->uploadsize_byte;

    my $uploader = $self->{uploader};
    my $work_fh  = $self->{work_fh};
    TRACE "work_fh type: ", ref $work_fh;

    _reset_workfile($work_fh);

    my ( $buffer, $part_context );
    my $size = 0;
    while (1) {

        # read from commands output
        $size += read( $fh, $buffer, $READ_UNIT );
        print $work_fh $buffer;

        if ( eof $fh ) {

            # check commands exit status
            eval { $piper->check_status; };
            if ($@) {
                $uploader->abort_upload( $part_context, $filename )
                    if $part_context;
                die $@;
            }

            seek $work_fh, 0, 0;
            if ($part_context) {
                INFO "part uploading $filename: size=", commify($size);
                my $num = $uploader->upload_part( $part_context, $filename,
                    $work_fh );
                INFO "part upload($num) done.";
                INFO "finalizing upload $filename";
                $uploader->complete_upload( $part_context, $filename );
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
                $part_context = $uploader->init_upload( $args, $filename );
                INFO "initialize done.";
            }

            seek $work_fh, 0, 0;
            INFO "part uploading $filename: size=", commify($size);
            my $num = $uploader->upload_part( $part_context, $filename,
                $work_fh );
            INFO "part upload($num) done.";

            _reset_workfile($work_fh);
            $size = 0;
        }
        else {
            ;    # nothing to do
        }
    }
    $size;
}

# internal methods

sub _create_piper {
    ShionBackup::PipeExec->new;
}

# internal functions

sub _reset_workfile {
    my ($fh) = @_;
    seek $fh, 0, 0;
    truncate $fh, 0;
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

