#!perl -T

use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok('ShionBackup::Config::Util::TypeCheck');
}
use ShionBackup::Logger;

#ShionBackup::Logger::set_log_level(LOG_TRACE);

# test: match_type
{

    # value
    ok match_type( 1, MATCH_VALUE( 1, 2 ) );
    ok match_type( 2, MATCH_VALUE( 1, 2 ) );
    eval { match_type( 3, MATCH_VALUE( 1, 2 ) ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    # type
    ok match_type( undef, [TYPE_UNDEF] );
    eval { match_type( undef, [TYPE_SCALAR] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( undef, [TYPE_ARRAY] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( undef, [TYPE_HASH] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    eval { match_type( 'a', [TYPE_UNDEF] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    ok match_type( 'a', [TYPE_SCALAR] );
    eval { match_type( 'a', [TYPE_ARRAY] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( 'a', [TYPE_HASH] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    eval { match_type( [], [TYPE_UNDEF] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( [], [TYPE_SCALAR] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    ok match_type( [], [TYPE_ARRAY] );
    eval { match_type( [], [TYPE_HASH] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    eval { match_type( {}, [TYPE_UNDEF] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( {}, [TYPE_SCALAR] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    eval { match_type( {}, [TYPE_ARRAY] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    ok match_type( {}, [TYPE_HASH] );

    ok match_type( undef, [TYPE_ANY] );
    ok match_type( 'a',   [TYPE_ANY] );
    ok match_type( [], [TYPE_ANY] );
    ok match_type( {}, [TYPE_ANY] );

    ok match_type( 'a', [ TYPE_SCALAR, TYPE_ARRAY ] );
    ok match_type( [], [ TYPE_SCALAR, TYPE_ARRAY ] );
    eval { match_type( {}, [ TYPE_SCALAR, TYPE_ARRAY ] ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    ok match_type( { foo => 'bar' }, { TYPE_HASH() => TYPE_SCALAR } );
    eval { match_type( { foo => undef }, { TYPE_HASH() => TYPE_SCALAR } ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    is_deeply $@->context, ["{foo}"];
    eval { match_type( { foo => 'bar' }, { TYPE_HASH() => [TYPE_UNDEF] } ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';

    ## typedeep
    ok match_type(
        { foo => [ { bar => "hoge" } ] },
        {   TYPE_HASH() => { TYPE_ARRAY() => { TYPE_HASH() => TYPE_SCALAR } },
        }
    );
    eval {
        match_type(
            { foo => [ { bar => undef } ] },
            {   TYPE_HASH() =>
                    { TYPE_ARRAY() => { TYPE_HASH() => TYPE_SCALAR }, },
            }
        );
    };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    is_deeply $@->context, [ '{foo}', '[1]', '{bar}' ];

    ## hash
    ok match_type(
        { foo => 'bar' },
        MATCH_HASH(
            foo  => TYPE_SCALAR(),
            hoge => TYPE_UNDEF(),
        )
    );
    eval {
        match_type(
            { foo => 1 },
            MATCH_HASH(
                foo => TYPE_SCALAR(),
                bar => TYPE_SCALAR(),
            )
        );
    };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    is_deeply $@->context, ['{bar}'];
}

## test: match_type_hash
{
    ok match_type_hash( { foo => 'bar' }, { foo => TYPE_SCALAR() } );
    eval { match_type_hash( { foo => undef }, { foo => TYPE_SCALAR() } ) };
    isa_ok $@, 'ShionBackup::Config::Util::TypeCheck::Unmatch';
    is_deeply $@->context, ['{foo}'];
}

## test: catch_unmatch
{
    my $mark;
    $mark = 0;
    eval {
        $@ = ShionBackup::Config::Util::TypeCheck::Unmatch->new;
        handle_unmatch { $mark = 1 };
    };
    is $mark, 1;

    $mark = 0;
    eval {
        $@ = "hoge\n";
        handle_unmatch { $mark = 1 };
    };
    is $mark, 0;
    is $@,    "hoge\n";
}

done_testing;

