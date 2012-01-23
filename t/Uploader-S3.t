#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('ShionBackup::Uploader::S3');
}
local $ShionBackup::Uploader::S3::TEST_MODE   = 1;
local $ShionBackup::Uploader::S3::BUFFER_SIZE = 10;

use ShionBackup::Logger;
local $ShionBackup::Logger::LOG_LEVEL = LOG_DEBUG;

package ShionBackup::Test::Uploader::S3;
use base qw(ShionBackup::Uploader::S3);

sub get_time {1313678905}

package main;

sub create_object {

# see
# http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?RESTAuthentication.html
    ShionBackup::Test::Uploader::S3->new(
        'http://johnsmith.s3.amazonaws.com/test/',
        '0PN5J17HBGZHT7JJ3X82', 'uV3F3YluFJax1cknvbcGwgjvx4QpvB+leU8dUj2o' );
}

# test: new
{
    ok create_object;
}

# test: build_authorization
#
# Content-Length: 5913339
{
    use HTTP::Headers;
    use URI;

    my $t = create_object;

    # PUT /db-backup.dat.gz HTTP/1.1
    # User-Agent: curl/7.15.5
    # Host: static.johnsmith.net:8080
    # Date: Tue, 27 Mar 2007 21:06:08 +0000
    # x-amz-acl: public-read
    # content-type: application/x-download
    # Content-MD5: 4gJE4saaMU4BqNR0kLY+lw==
    # X-Amz-Meta-ReviewedBy: joe@johnsmith.net
    # X-Amz-Meta-ReviewedBy: jane@johnsmith.net
    # X-Amz-Meta-FileChecksum: 0x02661779
    # X-Amz-Meta-ChecksumAlgorithm: crc32
    # Content-Disposition: attachment; filename=database.dat
    # Content-Encoding: gzip
    {
        my $header = HTTP::Headers->new(
            Host                      => 'static.johnsmith.net:8080',
            Date                      => 'Tue, 27 Mar 2007 21:06:08 +0000',
            'x-amz-acl'               => 'public-read',
            'content-type'            => 'application/x-download',
            'content-MD5'             => '4gJE4saaMU4BqNR0kLY+lw==',
            'X-Amz-Meta-ReviewedBy'   => 'joe@johnsmith.net',
            'X-Amz-Meta-ReviewedBy'   => 'jane@johnsmith.net',
            'X-Amz-Meta-FileChecksum' => '0x02661779',
            'X-Amz-Meta-ChecksumAlgorithm' => 'crc32',
            'Content-Disposition' => 'attachment; filename=database.dat',
            'Content-Encoding'    => 'gzip',
            'Content-Length'      => '5913339',
        );

        my $req = HTTP::Request->new(
            'PUT',
            URI->new_abs(
                '/db-backup.dat.gz', 'http://static.johnsmith.net:8080/'
            ),
            $header
        );
        is $t->sign_request($req)->authorization,
            'AWS 0PN5J17HBGZHT7JJ3X82:C0FlOtU8Ylb9KDTpZqYkZPX91iI='
    }

    # GET /photos/puppy.jpg HTTP/1.1
    # Host: johnsmith.s3.amazonaws.com
    # Date: Tue, 27 Mar 2007 19:36:42 +0000
    # Authorization: AWS 0PN5J17HBGZHT7JJ3X82:
    # xXjDGYUmKxnwqr5KXNPGldn5LbA=
    {
        my $header = HTTP::Headers->new(
            'Host' => 'johnsmith.s3.amazonaws.com',
            'Date' => 'Tue, 27 Mar 2007 19:36:42 +0000',
        );

        my $req = HTTP::Request->new(
            'GET',
            URI->new_abs(
                '/photos/puppy.jpg', 'http://johnsmith.s3.amazonaws.com/'
            ),
            $header
        );
        is $t->sign_request($req)->authorization,
            'AWS 0PN5J17HBGZHT7JJ3X82:xXjDGYUmKxnwqr5KXNPGldn5LbA='
    }
}

# test: build_resouce_string
{
    my $t = create_object;

    my $r = HTTP::Request->new( 'GET',
        'http://johnsmith.s3.amazonaws.com/?uploads&prefix=photos&max-keys=50&marker=puppy'
    );
    is $t->build_resource_string($r), '/johnsmith/?uploads';
}

# test: build_request
{
    my $t = create_object;

    {
        my $req = $t->build_request( 'PUT', 'file' );

        #diag $req->as_string;
        is( $req->authorization,
            'AWS 0PN5J17HBGZHT7JJ3X82:QAXzsKwUSh2E8iGLpFhsHJUWHQ0=' );
    }

    {
        my $req = $t->build_request( 'PUT', 'file', 'hogefuga' );
        is( $req->authorization,
            'AWS 0PN5J17HBGZHT7JJ3X82:PseVcxjATxNXe3MDheNufFArivw=' );
    }

    {
        use File::Basename qw(dirname);
        open my $fh, "<", dirname(__FILE__) . '/test/part1.txt' or die $!;
        my $req = $t->build_request( 'PUT', 'file', $fh );
        is( $req->authorization,
            'AWS 0PN5J17HBGZHT7JJ3X82:h2YQIjjG/WaIiFqp3UJZFxkRijE=' );
    }
}

done_testing();
