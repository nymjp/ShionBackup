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

    bless { children => {}, }, $class;
}

=back

=head2 METHODS

=over 4

=item run

=cut

sub run {
    my $self = shift;
    my ( $cmd, $infh, $args ) = @_;

    my ( $rfh, $wfh );
    pipe( $rfh, $wfh );

    my $pid = fork;
    if ($pid) {    # parent
        $self->{children}{$pid} = $cmd;

        close $wfh;
        return $rfh;
    }
    elsif ( defined $pid ) {    # child
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
            my @cmd = _process_args( $args, @$cmd );
            DEBUG $log, "run command: ", join " ", @cmd if IS_DEBUG;
            exec @cmd;
        }
        else {
            my $cmd_str = _process_args( $args, $cmd );
            DEBUG $log, "run command: $cmd_str";
            exec $cmd_str;
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

sub _process_args {
    my ( $args, @str ) = @_;
    map {
        s{\${(.*?)}}{
            my $key = $1;
            if ($key eq '$') { '$' }
            elsif ( $key =~ s/^([^:]+):(<|>)(.*$)/$1/ ) {
                $key = $1;
                if ( !defined $args->{$key} ) { "" }
                elsif ( $2 eq '<' ) {
                    "$3$args->{$key}";
                }
                elsif ( $2 eq '>' ) {
                    "$args->{$key}$3";
                }
                else { "" }
            }
            elsif ( defined $args->{$key} ) {
                $args->{$key};
            }
            else { "" }
        }gex;
    } @str;
    wantarray ? @str : pop @str;
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
