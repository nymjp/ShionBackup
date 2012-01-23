package ShionBackup::Config::Base;

=head1 NAME

ShionBackup::Config::Base - Config Base Class

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use YAML::Syck;

=head2 CONSTRUCTOR

=over 4

=item new

=cut

sub new {
    my $class = shift;
    bless {}, $class;
}

=back

=head2 METHODS PLACEHOLDERS

=over 4

=item raw

=item processed

=item process

=item merge

=cut

for my $field (qw[ raw processed process merge ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        croak "please implement $field.";
    };
}

=back

=head2 METHODS

=over 4

=item dump_raw

=cut

sub dump_raw {
    my $self = shift;
    local $YAML::Syck::SortKeys = 1;
    local $YAML::Syck::UseCode  = 1;
    Dump( $self->raw );
}

=item dump_processed

=cut

sub dump_processed {
    my $self = shift;
    local $YAML::Syck::SortKeys = 1;
    local $YAML::Syck::UseCode  = 1;
    Dump( $self->processed );
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

