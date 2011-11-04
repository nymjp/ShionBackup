#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'ShionBackup::NullUploader' ) || print "Bail out!
";
}
