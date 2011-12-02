package ShionBackup::Uploader::S3;

=encoding utf-8

=head1 NAME

ShionBackup::S3Uploader

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base 'ShionBackup::Uploader';
use Carp;
use ShionBackup::Logger;

use File::Spec::Functions qw(catfile);
use URI;
use URI::QueryParam;
use HTTP::Date;
use HTTP::Headers;
use HTTP::Request;
use Digest::HMAC_SHA1;
use Digest::MD5;
use LWP::UserAgent;

our $TEST_MODE   = undef;
our $BUFFER_SIZE = 4096 * 16;

my %RESOURCE_SUBREQUEST = map { $_ => 1 } qw(
    acl location logging notification partNumber policy requestPayment
    torrent uploadId uploads versionId versioning versions website
);

=head2 CONSTRUCTORS

=over 4

=item new( $url_base, $id, $secret )

=cut

sub new {
    my $class = shift;
    $class->SUPER::new(@_);
}

=back

=head2 METHODS

=over 4

=item get_time

=cut

sub get_time {
    return time();
}

=item sign_request( HTTP::Request $request ) : HTTP::Request

sub-resource is not supported.

=cut

sub sign_request {
    my $self      = shift;
    my ($request) = @_;
    my $verb      = $request->method;

    # header amz-
    my %amz;
    $request->scan(
        sub {
            my $key = lc shift;
            my $val = shift;
            return unless $key =~ /^x-amz-/;

            if ( exists $amz{$key} ) {
                $amz{$key} .= ",$val";
            }
            else {
                $amz{$key} = "$val";
            }
        }
    );

    # date
    my $ts = time2str( $request->date );
    $ts =~ s/GMT$/+0000/ if $TEST_MODE;

    my @string_to_sign = (
        $verb,
        $request->header('Content-MD5') // '',
        $request->content_type // '', $ts,
    );
    push @string_to_sign, join( "\n", map {"$_:$amz{$_}"} sort keys %amz )
        if keys %amz;

    push @string_to_sign, $self->build_resource_string($request);

    my $string_to_sign = join( "\n", @string_to_sign );

    DEBUG join "\n", "string_to_sign =>", "===", $string_to_sign, "==="
        if IS_DEBUG;
    my $hmac = Digest::HMAC_SHA1->new( $self->{secret} );
    $hmac->add($string_to_sign);

    $request->authorization(
        "AWS $self->{id}:" . $hmac->b64digest($string_to_sign) . '=' );
    $request;
}

=item build_resource_string( $request ) : string

=cut

sub build_resource_string {
    my $self      = shift;
    my ($request) = @_;
    my $uri       = $request->uri;

    my $resource = URI->new( '', 'http' );

    # backet
    if ( $uri->host =~ /^(?:([^.]+)[.])(s3[.]amazonaws[.]com)/ ) {
        $resource->host($1);
    }
    else {
        $resource->host( $uri->host );
    }

    # path
    $resource->path( $uri->path );

    # query
    for my $key ( sort $uri->query_param ) {
        next unless $RESOURCE_SUBREQUEST{$key};
        for my $val ( sort $uri->query_param($key) ) {
            $resource->query_param_append( $key, $val );
        }
    }
    my $query = $resource->query // '';
    $query =~ s/=$//;
    $query =~ s/=&/&/g;
    $query = "?$query" if $query ne '';

    '/' . $resource->host . $resource->path . $query;
}

=item build_request( $VERB, $URL, $CONTENT = undef, \%header = undef )

$URL は、相対URL でもよい。$CONTENT は、文字列かファイルハンドル。

=cut

sub build_request {
    my $self = shift;
    my ( $verb, $url, $content, $header_hash ) = @_;
    $header_hash = {} unless defined $header_hash;

    # URL
    $url = URI->new_abs( $url, $self->{url_base} );
    DEBUG "URL => $url";

    # MD5 / Length
    my $md5 = Digest::MD5->new;
    my ( $digest, $length );
    if ( ref $content eq 'GLOB' ) {
        $md5->addfile($content);
        $digest = $md5->b64digest;
        $length = ( stat $content )[7];
        seek $content, 0, 0;    # rewind
    }
    elsif ( defined $content ) {
        $md5->add($content);
        $digest = $md5->b64digest;
        $length = length $content;
    }
    else {
        ;
    }

    #header
    my $header = HTTP::Headers->new(%$header_hash);
    $header->date( $self->get_time );
    $header->header( Host => $url->host );

    if ( defined $content ) {
        $header->content_length($length);
        $header->header( 'Content-MD5' => "$digest==" );
    }

    # request
    my $request = HTTP::Request->new( $verb, $url, $header );
    if ( ref $content eq 'GLOB' ) {
        my $buffer;
        my $upload_length = 0;
        $request->content(
            sub {
                $upload_length += read $content, $buffer, $BUFFER_SIZE;
                if ( $self->is_show_progress ) {
                    my $complete_ratio = ( $upload_length * 1.0 ) / $length;
                    my $mark_num       = int( $complete_ratio * 20 );
                    printf STDERR (
                        "\r" . 'uploading [%s>%s] %3.1f%% %d/%d',
                        "=" x $mark_num,
                        "." x ( 20 - $mark_num ),
                        $complete_ratio * 100,
                        $upload_length,
                        $length
                    );
                    if ( length($buffer) == 0 ) {
                        print STDERR "\n";
                    }
                }
                $buffer;
            }
        );
    }
    else {
        $request->content($content);
    }

    # sign
    $self->sign_request($request);

    $request;
}

=item request( HTTP::Request $request )

=cut

sub request {
    my $self = shift;
    my ($request) = @_;

    return $self->{ua}->request($request);
}

=item upload( \%args, $filename, $content )

$content は文字列かファイルハンドル

=cut

sub upload {
    my $self = shift;
    my ( $args, $file, $content ) = @_;

    my %header;
    if ( $args->{S3_RRS} ) {
        $header{'x-amz-storage-class'} = 'REDUCED_REDUNDANCY';
    }

    my $request = $self->build_request( 'PUT', $file, $content, \%header );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    DEBUG "response =>\n", $response->as_string if IS_DEBUG;
    if ( $response->is_error ) {
        die $response->as_string;
    }
    1;
}

=item init_upload( \%args, $filename ) : $context

=cut

sub init_upload {
    my $self = shift;
    my ( $args, $file ) = @_;

    my $url = URI->new($file);
    $url->query_form( 'uploads' => undef );

    my %header;
    if ( $args->{S3_RRS} ) {
        $header{'x-amz-storage-class'} = 'REDUCED_REDUNDANCY';
    }

    my $request = $self->build_request( 'POST', $url, undef, \%header );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    DEBUG "response =>\n", $response->as_string if IS_DEBUG;
    if ( $response->is_error ) {
        die $response->as_string;
    }

    if ( $response->content !~ /<UploadId>\s*([^\s<]+)/ ) {
        die $response->as_string;
    }
    my $upload_id = $1;

    DEBUG "upload_id => $upload_id";

    return ShionBackup::Uploader::S3::PartData->new($upload_id);
}

=item upload_part( $context, $filename, $content )

=cut

sub upload_part {
    my $self = shift;
    my ( $context, $file, $content ) = @_;

    my $url = URI->new($file);
    $url->query_form(
        [   partNumber => $context->next_count,
            uploadId   => $context->id,
        ]
    );
    my $request = $self->build_request( 'PUT', $url, $content );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    DEBUG "response =>\n", $response->as_string if IS_DEBUG;
    if ( $response->is_error ) {
        die $response->as_string;
    }
    DEBUG "Response: ", $response->header('ETag');

    $context->add_part( $response->header('ETag') );
}

=item complete_upload( $context, $filename )

=cut

sub complete_upload {
    my $self = shift;
    my ( $context, $file ) = @_;

    my $url = URI->new($file);
    $url->query_form( uploadId => $context->id );

    my @line  = '<CompleteMultipartUpload>';
    my $count = 0;
    for my $etag ( @{ $context->parts } ) {
        ++$count;
        push @line,
            qq(<Part><PartNumber>$count</PartNumber><ETag>"$etag"</ETag></Part>);
    }
    push @line, '</CompleteMultipartUpload>';

    my $request = $self->build_request( 'POST', $url, join "\n", @line );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    DEBUG "response =>\n", $response->as_string if IS_DEBUG;
    if ( $response->is_error ) {
        die $response->as_string;
    }
    DEBUG "response =>\n", $response->content;

    $response->content;
}

=item abort_incomplete()

=cut

sub abort_incomplete {
    my $self       = shift;
    my @incomplete = @{ $self->get_incomplete };
    if (@incomplete) {
        INFO( scalar(@incomplete), " incomplete object(s) found." );
        for my $target ( @{ $self->get_incomplete } ) {
            INFO "abort: $target->[0] => $target->[1]";
            my $context
                = ShionBackup::Uploader::S3::PartData->new( $target->[1] );
            $self->abort_upload( $context, '/' . $target->[0] );
        }
    }
    else {
        INFO "no incomplete part objects found.";
    }
}

=item abort_upload( $context, $filename )

=cut

sub abort_upload {
    my $self = shift;
    my ( $context, $file ) = @_;

    my $url = URI->new($file);
    $url->query_form( uploadId => $context->id );

    my $request = $self->build_request( 'DELETE', $url, undef );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    DEBUG "response =>\n", $response->as_string if IS_DEBUG;
    if ( $response->is_error ) {
        die $response->as_string;
    }

    1;
}

=item get_incomplete( [$filename] )

=cut

sub get_incomplete {
    my $self   = shift;
    my ($file) = @_;
    my $url    = URI->new(
        defined $file
        ? ( $file, $self->{url_base} )
        : ( $self->{url_base} )
    );
    my $path = $url->path;
    $path =~ s!^/!!;

    $url->query_form(
        [   uploads => undef,
            prefix  => $path,
        ]
    );

    $url->path('/');
    my $request = $self->build_request( 'GET', $url, undef );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    if ( $response->is_error ) {
        die $response->as_string;
    }

    my $content = $response->content;
    my @upload;
    while ( $content =~ m!<Upload>\s*(.*?)\s*</Upload>!gisx ) {
        my $upload = $1;
        my ($key) = ( $upload =~ m!<Key>\s*(.*?)\s*</Key>!isx );
        my ($id)  = ( $upload =~ m!<UploadId>\s*(.*?)\s*</UploadId>!isx );
        push @upload, [ $key, $id ];
    }
    \@upload;
}

=item get_part( $context, $filename )

=cut

sub get_part {
    my $self = shift;
    my ( $context, $file ) = @_;

    my $url = URI->new($file);
    $url->query_form( uploadId => $context->id );

    my $request = $self->build_request( 'GET', $url, undef );
    DEBUG "request =>\n", $request->as_string if IS_DEBUG;

    my $response = $self->request($request);
    if ( $response->is_error ) {
        die $response->as_string;
    }

    $response->content;
}

1;

=back

=cut

package ShionBackup::Uploader::S3::PartData;

sub new {
    my $class = shift;
    my ($id) = @_;
    bless {
        id    => $id,
        parts => [],
    }, $class;
}

sub id {
    my $self = shift;
    $self->{id};
}

sub add_part {
    my $self = shift;
    my ($part) = @_;

    push @{ $self->{parts} }, $part;
    scalar @{ $self->{parts} };
}

sub parts {
    my $self = shift;
    $self->{parts};
}

sub next_count {
    my $self = shift;
    scalar @{ $self->{parts} } + 1;
}

1;
