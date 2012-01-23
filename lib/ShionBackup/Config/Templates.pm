package ShionBackup::Config::Templates;

=head1 NAME

ShionBackup::Config::Templates

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use ShionBackup::Logger;
use ShionBackup::Config::Util::TypeCheck;
use ShionBackup::Config::Template;

=head2 CONSTRUCTOR

=over 4

=item new

=cut

sub new {
    my $class = shift;
    my $self = bless { templates => {}, }, $class;
    $self;
}

=back

=head2 METHODS

=over 4

=item get( $name )

=cut

sub get {
    my $self = shift;
    my ($name) = @_;
    $self->{templates}{$name};
}

=item merge( \%hash )

=cut

sub merge {
    my $self = shift;
    my ($hash) = @_;

    match_type( $hash, TYPE_HASH );

    while ( my ( $name, $conf ) = each %$hash ) {
        my $tmpl = $self->{templates}{$name};

        if ($tmpl) {
            $tmpl->merge($conf);
        }
        else {
            $self->{templates}{$name}
                = ShionBackup::Config::Template->new($conf);
        }
    }
    1;
}

=item process()

=cut

sub process {
    my $self = shift;

    while ( my ( $name, $template ) = each %{ $self->{templates} } ) {
        eval { $template->process };
        handle_unmatch { unshift @{ shift->context }, "{$name}" };
    }
}

=back

=head2 D/A METHODS

=over 4

=item raw, set_raw

=item processed, set_processed

=cut

for my $field (qw[ raw processed ]) {
    my $slot_get = __PACKAGE__ . "::$field";
    no strict 'refs';
    *$slot_get = sub {
        my $self = shift;

        my $hash = {};
        while ( my ( $k, $v ) = each %{ $self->{templates} } ) {
            $hash->{$k} = $v->$field;
        }
        $hash;
    };
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

