#!/usr/bin/perl

use strict;
use warnings;

use ShionBackup;
use ShionBackup::Logger;

eval {
    ShionBackup->run(@ARGV);
};
if ($@) {
    FATAL $@;
    die $@;
}
