package ShionBackup::Uploader;

=encoding utf-8

=head1 NAME

ShionBackup::Uploader

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use ShionBackup::Logger;

=head2 CONSTRUCTORS

=over 4

=item new( $url_base, $id, $secret )

=cut

sub new {
    my $class = shift;
    bless {}, $class;
}

=back

=head2 METHODS

=over 4

=item upload( $filename, $content )

$content は文字列かファイルハンドル

=cut

sub upload {
    croak "implement me!!";
}

=item init_upload( $filename )

=cut

sub init_upload {
    croak "implement me!!";
}

=item upload_part( $filename, $content ) : $part_num

1から始まる部分の番号を返す。

=cut

sub upload_part {
    croak "implement me!!";
}

=item complete_upload( $filename )

=cut

sub complete_upload {
    croak "implement me!!";
}

=item abort_incomplete()

=cut

sub abort_incomplete {
    croak "implement me!!";
}

=item abort_upload( $filename )

=cut

sub abort_upload {
    croak "implement me!!";
}

1;

=back

=cut
