package ShionBackup::Config::Target;

=head1 NAME

ShionBackup::Config::Target

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use base qw(ShionBackup::Config::SectionBase);
use ShionBackup::Util;
use ShionBackup::Logger;
use ShionBackup::Config::Util;
use ShionBackup::Config::Util::TypeCheck;

=head2 CONSTRUCTOR

=over 4

=item new( Config::Templates $templates, @_ );

=cut

sub new {
    my $class = shift;
    my ($templates) = splice @_, 0, 1;
    my $self = $class->SUPER::new(@_);
    $self->{templates} = $templates;
    $self;
}

=back

=head2 D/A METHODS

=over 4

=item filename

=item uploadsize_byte

=item arg

=item template

=item command

=cut

for my $field (qw[ filename uploadsize_byte arg template command ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;
        $self->processed->{$field};
    };
}

=item uploadsize

[廃止]

return uploadsize by (MB)

=cut

sub uploadsize {
    my $self = shift;
    my $size = $self->processed->{uploadsize_byte} or return;

    carp "ShionBackup::Config::Target::uploadsize() was deprecated!!";
    $size / 1_000_000;    # MB to Byte
}

=item command_array

return command with array.

=cut

sub command_array {
    my $self    = shift;
    my $command = $self->processed->{command};
    if ( ref $command eq 'ARRAY' ) {
        return $command;
    }
    elsif ( ref $command eq 'HASH' ) {
        return [ map { $command->{$_} } sort keys %$command ];
    }
    else {
        die "unknown type command: $command";
    }
}

=back

=head2 METHODS

=over 4

=item check_raw

=cut

sub check_raw {
    my $self = shift;
    my ($raw) = @_;

    match_type(
        $raw,
        MATCH_HASH(
            filename => TYPE_SCALAR,
            arg      => [ TYPE_UNDEF, TYPE_HASH ],
            template => {
                TYPE_UNDEF()  => undef,
                TYPE_SCALAR() => undef,
                TYPE_ARRAY()  => TYPE_SCALAR(),
            },
            command => {
                TYPE_UNDEF() => undef,
                TYPE_ARRAY() => [ TYPE_SCALAR, TYPE_CODE, ],
                TYPE_HASH()  => [ TYPE_SCALAR, TYPE_CODE, ],
            },
            uploadsize      => [ TYPE_UNDEF, TYPE_SCALAR ],
            uploadsize_byte => [ TYPE_UNDEF, TYPE_SCALAR ],
        )
    );
}

=item process_elements

=cut

sub process_elements {
    my $self = shift;
    my ($raw) = @_;

    my $newhash = {
        filename        => undef,
        arg             => {},
        template        => [],
        command         => {},
        uploadsize_byte => undef,
    };
    my $template = $raw->{template} = (
         !defined $raw->{template} ? []
        : ref $raw->{template} eq '' ? [ $raw->{template} ]
        : $raw->{template}
    );
    $self->_process_template( $newhash, $template );
    merge_deeply( $newhash, $raw );

    ## process arg
    $self->_process_arg_code($newhash);
    $self->_process_command_arg($newhash);

    ## process uploadsize
    if (  !defined $newhash->{uploadsize_byte}
        && defined $newhash->{uploadsize} )
    {
        $newhash->{uploadsize_byte}
            = delete( $newhash->{uploadsize} ) * 1_000_000;
    }

    $newhash;
}

sub _process_template {
    my $self = shift;
    my ( $hash, $tnames, $merged ) = @_;

    $merged ||= {};

    # expand template
    for my $name (@$tnames) {
        if ( $merged->{$name} ) {
            ## already merged;
            WARN "template '$name' was already merged.";
            next;
        }
        $merged->{$name} = 1;

        my $tmpl = $self->{templates}->get($name);
        if ( !defined $tmpl ) {
            WARN "not found template '$name'.";
            next;
        }

        if ( @{ $tmpl->template } ) {
            TRACE "pre merge: ", join ',', @{ $tmpl->template } if IS_DEBUG;
            $self->_process_template( $hash, $tmpl->template, $merged );
        }

        DEBUG "merge: $name";
        merge_deeply( $hash, $tmpl->processed );
    }

    $hash;
}

sub _process_arg_code {
    my $self = shift;
    my ($hash) = @_;

    process_perl_deeply( $hash->{arg} );
    $hash;
}

sub _process_command_arg {
    my $self = shift;
    my ($hash) = @_;

    my $arg     = $hash->{arg};
    my $command = $hash->{command};

    if ( ref $command eq 'HASH' ) {
        for my $key ( sort keys %$command ) {
            $command->{$key} = expand_arg( $arg, $command->{$key} );
        }
    }
    elsif ( ref $command eq 'ARRAY' ) {
        @$command = expand_arg( $arg, @$command );
    }
    else {
        ;
    }
    $hash;
}

=item check_processed

=cut

sub check_processed {
    my $self = shift;
    my ($hash) = @_;

    match_type(
        $hash,
        MATCH_HASH(
            filename        => TYPE_SCALAR,
            uploadsize      => TYPE_UNDEF,
            uploadsize_byte => [ TYPE_UNDEF, TYPE_SCALAR ],
            arg             => TYPE_HASH,
            template        => { TYPE_ARRAY() => TYPE_SCALAR() },
            command         => {
                TYPE_CODE()  => undef,
                TYPE_ARRAY() => [ TYPE_SCALAR, TYPE_CODE, ],
                TYPE_HASH()  => [ TYPE_SCALAR, TYPE_CODE, ],
            },
        )
    );
    1;
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>
