package ShionBackup::Config::SectionBase;

=head1 NAME

ShionBackup::Config::SectionBase

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use base qw(ShionBackup::Config::Base);
use ShionBackup::Util;
use ShionBackup::Config::Util::TypeCheck;

=head2 CONSTRUCTOR

=over 4

=item new

=cut

sub new {
    my $class      = shift;
    my ($elements) = @_;
    my $self       = $class->SUPER::new;
    $self->{raw}       = {};
    $self->{processed} = undef;

    $self->merge($elements) if defined $elements;
    $self;
}

=back

=head2

=over 4

=item raw

=item processed

=item set_processed

=cut

sub raw {
    shift->{raw};
}

sub processed {
    my $self = shift;
    $self->process;
    $self->{processed};
}

sub set_processed {
    $_[0]->{processed} = $_[1];
}

=back

=head2 METHODS

=over 4

=item set( $key, $value )

=cut

sub set {
    my $self = shift;
    my ( $key, $value ) = @_;
    undef $self->{processed};
    $self->{raw}{$key} = $value;
}

=item merge( \%new_elements )

=cut

sub merge {
    my $self = shift;
    my ($new_elements) = @_;

    undef $self->{processed};
    merge_deeply( $self->{raw}, $new_elements );
    1;
}

=item process()

=cut

sub process {
    my $self = shift;
    return 1 if $self->{processed};    # already processed

    match_type( $self->{raw}, TYPE_HASH );

    $self->check_raw( $self->{raw} );
    $self->{processed}
        = $self->process_elements( merge_deeply( {}, $self->{raw} ) );
    $self->check_processed( $self->{processed} );
    1;
}

=item check_raw(\%raw)

=cut

sub check_raw {
    croak "implement cehck_raw!!";
}

=item process_elements(\%raw) : \%processed

=cut

sub process_elements {
    croak "implement process_elements!!";
}

=item check_processed(\%processed)

=cut

sub check_processed {
    croak "implement check_processed!!";
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

