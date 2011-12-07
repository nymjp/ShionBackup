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
    my ( $url_base, $id, $secret ) = @_;
    DEBUG $class, "::new( url_base=$url_base, id=$id, secret=*** )";
    INFO "url base: $url_base";
    bless {
        url_base => URI->new($url_base),
        id       => $id,
        secret   => $secret,

        ua               => LWP::UserAgent->new,
        is_show_progress => undef,
    }, $class;
}

=back

=head2 CLASS METHODS

=over 4

=item create( \%uploader_config )

=cut

sub create {
    my $class = shift;
    my ($config) = @_;

    my $uploader_class = $config->{class};
    eval "use ShionBackup::Uploader::$uploader_class";
    die $@ if ($@);

    "ShionBackup::Uploader::$uploader_class"
        ->new( $config->{baseurl}, $config->{id}, $config->{secret} );
}

=back

=head2 METHODS

=over 4

=item is_show_progress(): bool

=cut

sub is_show_progress {
    my $self = shift;
    $self->{is_show_progress};
}

=item set_show_progress( bool )

=cut

sub set_show_progress {
    my $self = shift;
    my ($is_show_progess) = @_;
    $self->{is_show_progress} = $is_show_progess;
}

=item upload( \%args, $filename, $content )

$content は文字列かファイルハンドル

=cut

sub upload {
    croak "implement me!!";
}

=item init_upload( \%args, $filename ) : $context

=cut

sub init_upload {
    croak "implement me!!";
}

=item upload_part( $context, $filename, $content ) : $part_num

1から始まる部分の番号を返す。

=cut

sub upload_part {
    croak "implement me!!";
}

=item complete_upload( $context, $filename )

=cut

sub complete_upload {
    croak "implement me!!";
}

=item abort_upload( $context, $filename )

=cut

sub abort_upload {
    croak "implement me!!";
}

=item abort_incomplete()

=cut

sub abort_incomplete {
    croak "implement me!!";
}

1;

=back

=cut
