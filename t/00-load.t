#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('ShionBackup') || print "Bail out!
";
}

diag("Testing ShionBackup $ShionBackup::VERSION, Perl $], $^X");
