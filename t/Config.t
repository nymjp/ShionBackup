#!perl -T

use Test::More 'no_plan';
use strict;
use warnings;

BEGIN {
    use_ok('ShionBackup::Config');
}

use ShionBackup::Logger;
local $ShionBackup::Logger::LOG_LEVEL = LOG_DEBUG;

# test: _merge_deep
{
    local *merge_deep = \&ShionBackup::Config::_merge_deep;

    my ( $dst, $src );

    # scalar
    $src = 'a';
    is_deeply merge_deep( $dst, $src ), $src;
    is_deeply $dst, $src;
    $src = 'b';
    is_deeply merge_deep( $dst, $src ), $src;

    # array
    $src = [qw( a b )];
    is_deeply merge_deep( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    # hash
    $src = { a => 1, b => 2 };
    is_deeply merge_deep( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    # hash/array complex
    $src = { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ] };
    undef $dst;
    is_deeply merge_deep( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    $dst = { b => 42, z => 999 };
    is_deeply merge_deep( $dst, $src ),
        { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ], z => 999 };
}

# test: _preprocess_templates
{
    local *preprocess_templates
        = \&ShionBackup::Config::_preprocess_templates;

    my $config = {
        templates => {
            base => { args => { foo => 'bar' } },
            A1   => {
                template => 'base',
                args     => { hoge => 'fuga' },
            },
        },
    };
    preprocess_templates($config);
    is_deeply(
        $config,
        {   templates => {
                base => { args => { foo => 'bar', }, },
                A1   => {
                    args => {
                        foo  => 'bar',
                        hoge => 'fuga',
                    },
                },
            },
        }
    );
}

# test: _preprocess_targets
{
    local *preprocess_targets = \&ShionBackup::Config::_preprocess_targets;

    my $config = {
        args => {
            hoge => 'fuga',
            foo  => undef,
        },
        templates => {
            A => {
                commands => {
                    1 => 'foo',
                    2 => 'bar',
                    3 => 'hoge',
                },
            },
        },
        targets => [
            {   name     => 'test1',
                template => ['A'],
                args     => { foo => 'bar', },
                commands => { 2 => 'fuga', },
            },
        ],
    };

    is_deeply preprocess_targets($config),
        [
        {   name     => 'test1',
            template => ['A'],
            args     => {
                hoge => 'fuga',
                foo  => 'bar',
            },
            commands => [ 'foo', 'fuga', 'hoge', ],
        },
        ];
}
