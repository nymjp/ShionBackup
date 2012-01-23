package ShionBackup::Config::Uploader;

=head1 NAME

ShionBackup::Config::Uploader - config 'uploader' section element

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use base qw(ShionBackup::Config::SectionBase);
use ShionBackup::Util;
use ShionBackup::Config::Util::TypeCheck;

=head2 CONSTRUCTOR

=over 4

=item new

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    @{ $self->{ 'class', 'id', 'secret' } } = ();
    $self;
}

=back

=head2 D/A METHODS

=over 4

=item class, set_class

=item id

=item secret

=item url

=cut

for my $field (qw[ class id secret url ]) {
    my $slot = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot = sub {
        my $self = shift;
        $self->process;
        $self->processed->{$field};
    };
}

sub set_class {
    my $self = shift;
    my ($class) = @_;
    $self->set( 'class', $class );
}

=item check_raw

=cut

sub check_raw {
    my $self = shift;
    my ($raw) = @_;

    match_type(
        $raw,
        MATCH_HASH(
            class  => [ TYPE_UNDEF,  TYPE_SCALAR ],
            id     => [ TYPE_SCALAR, TYPE_CODE ],
            secret => [ TYPE_SCALAR, TYPE_CODE ],
            url    => [ TYPE_SCALAR, TYPE_CODE ],
        )
    );
    1;
}

=item process_elements

=cut

sub process_elements {
    my $self  = shift;
    my ($raw) = @_;
    my $hash  = process_perl_deeply($raw);
    $hash->{class} = 'S3' unless defined $hash->{class};    # default value
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
            class  => TYPE_SCALAR,
            id     => TYPE_SCALAR,
            secret => TYPE_SCALAR,
            url    => TYPE_SCALAR,
        )
    );
    1;
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

