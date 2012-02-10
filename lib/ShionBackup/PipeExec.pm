package ShionBackup::PipeExec;

=head1 NAME

ShionBackup::PipeExec

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use ShionBackup::Logger;

=head2 CONSTRUCTORS

=over 4

=item new

=cut

sub new {
    my $class = shift;

    bless {
        children  => {},
        output_fh => undef,
    }, $class;
}

=back

=head2 D/A METHODS

=over 4

=item output_fh

=cut

sub output_fh {
    shift->{output_fh};
}

=back

=head2 METHODS

=over 4

=item run( $cmd, $args [,$infh] )

=cut

sub run {
    my $self = shift;
    my ( $cmd, $args, $infh ) = @_;

    my ( $rfh, $wfh );
    pipe( $rfh, $wfh );

    my $pid = fork;
    if ($pid) {    # parent
        $self->{children}{$pid} = $cmd;

        close $wfh;
        $self->{output_fh} = $rfh;
        return $rfh;
    }
    elsif ( defined $pid ) {    # child
        $infh = $self->{output_fh} unless defined $infh;
        undef $self->{output_fh};
        close $rfh;

        open my $log, '>&', STDOUT;
        open STDOUT, '>&', $wfh or die "Can't dup 'out' file handle: $!";
        if ($infh) {
            open STDIN, '<&', $infh or die "Can't dup 'in' file handle: $!";
        }

        my $cmd_type = ref $cmd;
        if ( $cmd_type eq 'CODE' ) {
            DEBUG $log, "run code";
            $cmd->($args);
            exit 0;
        }
        elsif ( $cmd_type eq 'ARRAY' ) {
            DEBUG $log, "run command: ", join " ", @$cmd if IS_DEBUG;
            exec @$cmd;
        }
        else {
            DEBUG $log, "run command: $cmd";
            exec $cmd;
        }
    }
    else {
        die "fork failed.\n";
    }
}

=item check_status

=cut

sub check_status {
    my $self = shift;

    my @errors;
    for my $pid ( sort keys %{ $self->{children} } ) {
        waitpid $pid, 0;
        if ($?) {
            push @errors,
                "status=$?:" . _dump_command( $self->{children}{$pid} );
        }
    }
    $self->{children} = {};

    if (@errors) {
        die "some commands failed: ", join( "\n  ", @errors ), "\n";
    }
    1;
}

sub _dump_command {
    my $cmd = shift;

    my $cmd_type = ref $cmd;
    if ( $cmd_type eq 'ARRAY' ) {
        return join ' ', @$cmd;
    }
    else {
        return "$cmd";
    }
}

1;

=back

=cut
