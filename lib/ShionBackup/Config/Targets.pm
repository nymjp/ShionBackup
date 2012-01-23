package ShionBackup::Config::Targets;

=head1 NAME

ShionBackup::Config::Targets

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use base qw(ShionBackup::Config::Base);
use ShionBackup::Logger;
use ShionBackup::Config::Target;
use ShionBackup::Config::Util::TypeCheck;

=head2 CONSTRUCTOR

=over 4

=item new( ShionBackup::Config::Templates $templates )

=cut

sub new {
    my $class       = shift;
    my ($templates) = @_;
    my $self        = $class->SUPER::new;
    $self->{templates} = $templates;
    $self->{targets}   = [];
    $self;
}

=back

=head2 METHODS

=over 4

=item all() : []

=cut

sub all {
    shift->{targets};
}

=item merge( \@targets )

=cut

sub merge {
    my $self = shift;
    my ($targets) = @_;

    match_type( $targets, TYPE_ARRAY );

    for my $target (@$targets) {
        push @{ $self->{targets} },
            ShionBackup::Config::Target->new( $self->{templates}, $target );
    }
    1;
}

=item process()

=cut

sub process {
    my $self = shift;

    my $count = 0;
    for my $target ( @{ $self->{targets} } ) {
        eval { $target->process };
        handle_unmatch {
            unshift @{ shift->context }, "[$count]";
        };
    }
    continue {
        ++$count;
    }
}

=back

=head2 D/A METHODS

=over 4

=item raw

=item processed

=cut

for my $field (qw[ raw processed ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;

        my $array = [];
        for my $t ( @{ $self->{targets} } ) {
            push @$array, $t->$field();
        }
        $array;
    };
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

