package ShionBackup::Config;

=head1 NAME

ShionBackup::Config

=cut

use strict;
use warnings;
use YAML::Syck;
use base qw( ShionBackup::Config::Base );
use ShionBackup::Logger;
use ShionBackup::Util;
use ShionBackup::Config::Util::TypeCheck;
use ShionBackup::Config::Uploader;
use ShionBackup::Config::Templates;
use ShionBackup::Config::Targets;

my $config = {};

=head1 DESCRIPTION

=head2 CONTRACTORS

=over 4

=item new

=cut

sub new {
    my $class = shift;

    my $templates = ShionBackup::Config::Templates->new;
    my $targets   = ShionBackup::Config::Targets->new($templates);
    my $self      = $class->SUPER::new;
    $self->{uploader} = ShionBackup::Config::Uploader->new;
    $self->{template} = $templates;
    $self->{target}   = $targets;
    $self;
}

=back

=head2 METHODS

=over 4

=item load( @filename )

=cut

sub load {
    my $self  = shift;
    my @files = @_;

    local $YAML::Syck::ImplicitUnicode = 1;
    local $YAML::Syck::UseCode         = 1;

    for my $file (@files) {
        my $data = eval { LoadFile($file) };
        if ($@) {
            die "$file: $@\n";
        }
        $self->merge($data);
    }

    DEBUG Dump( $self->raw ) if IS_DEBUG;

    $self;
}

=item merge( \%hash )

=cut

sub merge {
    my $self = shift;
    my ($hash) = @_;

    match_type( $hash, TYPE_HASH );

    for my $field (qw( uploader template target )) {
        if ( defined $hash->{$field} ) {
            $self->{$field}->merge( $hash->{$field} );
        }
    }
}

=item process

=cut

sub process {
    my $self = shift;

    for my $field (qw( uploader template target )) {
        eval { $self->{$field}->process };
        if ($@) {
            FATAL "configuration error found in $field section.";
            handle_unmatch { unshift @{ shift->context }, "{$field}" };
        }
    }
}

=back

=head2 D/A METHODS

=over 4

=item uploader

=item template

=item target

=cut

for my $field (qw[ uploader template target ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;
        $self->{$field};
    };
}

=item raw

=item processed

=cut

for my $field (qw[ raw processed ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;
        {   uploader => $self->{uploader}->$field,
            template => $self->{template}->$field,
            target   => $self->{target}->$field,
        };
    };
}

=item dump_target

=cut

sub dump_target {
    my $self = shift;
    $self->{target}->dump_processed;
}

1;

=back

=head1 CONFIG STRUCTURE

 $config = {
   uploader => \%uploader,
   template => \%template,
   target   => \%target,
 }
 
 %uploader = (
   id     => <STRING> or <CODE>,
   secret => <STRING> or <CODE>,
   url    => <STRING> or <CODE>, # base url
 )
 
 %template = (
   <TEMPLATE_NAME> => \%target,
   ...
 )
 
 %target = (
   filename => <STRING>,
   arg      => \%arg,
   command  => \@command or \%command,
   
   # optional
   template   => $template_name or \@template_name,
   uploadsize => <INTEGER>, # (MB)
 )
 
 $template_name = <STRING>
 @template_name = ( $template_ref, ... )
 
 @command = ( $command, ... )
 %command = ( # run by NAME order
   <NAME> => $command,
   ...
 )
 $command = <STRING> or <CODE>

=cut
