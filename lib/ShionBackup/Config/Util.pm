package ShionBackup::Config::Util;

=head1 NAME

ShionBackup::Config::Util

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use base qw(Exporter);

our @EXPORT = qw(expand_arg);

=head2 Functions

=over 4

=item expand_arg( \%arg, @str ) : @

=cut

sub expand_arg {
    my ( $args, @str ) = @_;
    map {
        return unless defined $_;
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

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

