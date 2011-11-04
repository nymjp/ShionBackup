package ShionBackup::NullUploader;

=encoding utf-8

=head1 NAME

ShionBackup::NullUploader

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use Carp;
use ShionBackup::Logger;

=head2 CONSTRUCTORS

=over 4

=item new()

=cut

sub new {
    my $class = shift;
    bless { count => undef, }, $class;
}

sub _get_length($) {
    return ( stat $_[0] )[7];
}

=back

=head2 METHODS

=over 4

=item upload( $filename, $content )

$content は文字列かファイルハンドル

=cut

sub upload {
    my $self = shift;
    my ( $filename, $content ) = @_;
    INFO( "=DUMMY UPLOAD= upload: filename=$filename, content length=",
        _get_length($content) );
    return 1;
}

=item init_upload( $filename )

=cut

sub init_upload {
    my $self = shift;
    my ($filename) = @_;
    $self->{count} = 0;
    INFO("=DUMMY UPLOAD= init_upload: filename=$filename");
    return 1;
}

=item upload_part( $filename, $content ) : $part_num

1から始まる部分の番号を返す。

=cut

sub upload_part {
    my $self = shift;
    my ( $filename, $content ) = @_;
    INFO( "=DUMMY UPLOAD= upload_part: filename=$filename, content length=",
        _get_length($content) );
    return ++$self->{count};
}

=item complete_upload( $filename )

=cut

sub complete_upload {
    my $self = shift;
    my ($filename) = @_;
    INFO("=DUMMY UPLOAD= complete_upload: filename=$filename");
    undef $self->{count};
    return 1;
}

=item abort_upload( $filename )

=cut

sub abort_upload {
    my $self = shift;
    my ($filename) = @_;
    INFO("=DUMMY UPLOAD= abort_upload: filename=$filename");
    return 1;
}

1;

=back

=cut
