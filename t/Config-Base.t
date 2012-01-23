#!perl -T

use Test::More;

BEGIN {
    use_ok('ShionBackup::Config::Base');
}

sub create_object {
    ShionBackup::Config::Base->new();
}

done_testing;
