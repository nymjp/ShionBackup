package ShionBackup::Uploader::Null;

=encoding utf-8

=head1 NAME

ShionBackup::Uploader::Null

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base 'ShionBackup::Uploader';
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

=item upload( \%args, $filename, $content )

$content は文字列かファイルハンドル

=cut

sub upload {
    my $self = shift;
    my ( $args, $filename, $content ) = @_;
    INFO( "=DUMMY UPLOAD= upload: filename=$filename, content length=",
        _get_length($content) );
    return 1;
}

=item init_upload( \%args, $filename ) : $context

=cut

sub init_upload {
    my $self = shift;
    my ( $args, $filename ) = @_;
    $self->{count} = 0;
    INFO("=DUMMY UPLOAD= init_upload: filename=$filename");
    return 1;
}

=item upload_part( $context, $filename, $content ) : $part_num

1から始まる部分の番号を返す。

=cut

sub upload_part {
    my $self = shift;
    my ( $context, $filename, $content ) = @_;
    INFO( "=DUMMY UPLOAD= upload_part: filename=$filename, content length=",
        _get_length($content) );
    return ++$self->{count};
}

=item complete_upload( $context, $filename )

=cut

sub complete_upload {
    my $self = shift;
    my ( $context, $filename ) = @_;
    INFO("=DUMMY UPLOAD= complete_upload: filename=$filename");
    undef $self->{count};
    return 1;
}

=item abort_upload( $context, $filename )

=cut

sub abort_upload {
    my $self = shift;
    my ( $context, $filename ) = @_;
    INFO("=DUMMY UPLOAD= abort_upload: filename=$filename");
    return 1;
}

=item abort_incomplete()

=cut

sub abort_incomplete {
    my $self = shift;
    INFO("=DUMMY UPLOAD= abort_incomplete");
    return 1;
}

1;

=back

=cut
