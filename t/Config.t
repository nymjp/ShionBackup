#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('ShionBackup::Config');
}
use ShionBackup::Logger;

#ShionBackup::Logger::set_log_level( LOG_TRACE );

sub create_object {
    ShionBackup::Config->new();
}

# test: new
{
    my $t = create_object;
    isa_ok $t, 'ShionBackup::Config';
}

# test: merge
{
    my $t = create_object;

    $t->merge(
        {   uploader => {
                id     => 'foo',
                secret => 'bar',
                url    => 'file://',
            },
            template => { foo => { arg => { foo => 'fooval' } }, },
            target   => [
                {   filename => 'test',
                    template => 'foo',
                }
            ],
        }
    );
    is_deeply $t->raw,
        {
        uploader => {
            id     => 'foo',
            secret => 'bar',
            url    => 'file://',
        },
        template => { foo => { arg => { foo => 'fooval' } }, },
        target   => [
            {   filename => 'test',
                template => 'foo',
            }
        ],
        };

    is_deeply $t->processed,
        {
        uploader => {
            class  => 'S3',
            id     => 'foo',
            secret => 'bar',
            url    => 'file://',
        },
        template => {
            foo => {
                arg      => { foo => 'fooval' },
                template => [],
            },
        },
        target => [
            {   filename   => 'test',
                uploadsize => undef,
                arg        => { foo => 'fooval' },
                template   => ['foo'],
                command    => {},
            }
        ],
        };
}

done_testing;
