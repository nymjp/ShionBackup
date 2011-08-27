#!/usr/bin/perl

use strict;
use warnings;

use ShionBackup::Logger;
use ShionBackup::Config;
use ShionBackup::PipeExec;
use ShionBackup::S3Uploader;
use ShionBackup;

ShionBackup->run(@ARGV);
