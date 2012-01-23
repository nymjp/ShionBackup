#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('ShionBackup::Uploader::Null') || print "Bail out!
";
}
