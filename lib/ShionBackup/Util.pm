package ShionBackup::Util;

=head1 NAME

ShionBackup::Util

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Exporter);

our @EXPORT = qw(merge_deeply apply_deeply process_perl process_perl_deeply);

=head2 FUNCTIONS

=over 4

=item merge_deeply( dst, \src )

=cut

sub merge_deeply {
    my $dstr     = \$_[0];
    my $src      = $_[1];
    my $src_type = ref($src);

    if ( $src_type eq 'ARRAY' ) {
        $$dstr = [] unless ref($$dstr) eq 'ARRAY';
        push @$$dstr, @$src;
    }
    elsif ( $src_type eq 'HASH' ) {
        $$dstr = {} unless ref($$dstr) eq 'HASH';
        for my $key ( keys %$src ) {
            merge_deeply( $$dstr->{$key}, $src->{$key} );
        }
    }
    else {
        $$dstr = $src;
    }
    $$dstr;
}

=item apply_deeply( $subject, \&func(@args), [@args] )

ARRAY, HASH を再帰的に訪問し、スカラに &func を適用する。

このとき $_ は、現在訪問中のスカラのエイリアスである。

=cut

sub apply_deeply {
    my $subj = \shift;
    my $type = ref $$subj;

    if ( $type eq 'ARRAY' ) {
        apply_deeply( $_, @_ ) for (@$$subj);
    }
    elsif ( $type eq 'HASH' ) {
        apply_deeply( $_, @_ ) for ( values %$$subj );
    }
    else {
        local *_ = $subj;
        my $func = shift;
        $func->(@_);
    }
    return $$subj;
}

=item process_perl( \&func, @args )

=cut

sub process_perl {
    my ( $func, @args ) = @_;
    my $ret = eval { $func->(@args) };
    if ($@) {
        my $reason = $@;
        require B::Deparse;
        die "run code faild: reason=", $reason, 'code=',
            B::Deparse->new()->coderef2text($func), "\n";
    }
    $ret;
}

=item process_perl_deeply( \*element, @args )

=cut

sub process_perl_deeply {
    my $subj = \shift;
    my @args = @_;
    apply_deeply(
        $$subj,
        sub {
            if ( ref $_ eq 'CODE' ) {
                $_ = process_perl( $_, @args );
            }
        }
    );
    $$subj;
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

