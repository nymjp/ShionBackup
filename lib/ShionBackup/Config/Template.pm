package ShionBackup::Config::Template;

=head1 NAME

ShionBackup::Config::Template - config 'templates' section element

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(ShionBackup::Config::SectionBase);
use ShionBackup::Config::Util::TypeCheck;

=head2 CONSTRUCTOR

=over 4

=item new

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self;
}

=back

=head2 D/A METHODS

=over 4

=item template

=cut

for my $field (qw[ template ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;
        $self->processed->{$field};
    };
}

=back

=head2 METHODS

=over 4

=item check_raw

=cut

sub check_raw {
    my $self = shift;
    my ($hash) = @_;

    match_type( $hash,
        MATCH_HASH( template => [ TYPE_UNDEF, TYPE_SCALAR, TYPE_ARRAY ], ) );

    1;

}

=item process_elements

=cut

sub process_elements {
    my $self = shift;
    my ($raw) = @_;

    $raw->{template}
        = !defined $raw->{template} ? []
        : ref $raw->{template} eq '' ? [ $raw->{template} ]
        :                              $raw->{template};
    $raw;
}

=item check_processed

=cut

sub check_processed {
    my $self = shift;
    my ($hash) = @_;

    match_type( $hash, MATCH_HASH( template => TYPE_ARRAY, ) );
    1;
}

1;

__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

