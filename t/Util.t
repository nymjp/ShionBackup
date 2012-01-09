#!perl -T

use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Util');
}

# test: merge_deep
{
    my ( $dst, $src );

    # scalar
    $src = 'a';
    is_deeply merge_deeply( $dst, $src ), $src;
    is_deeply $dst, $src;
    $src = 'b';
    is_deeply merge_deeply( $dst, $src ), $src;

    # array
    $src = [qw( a b )];
    is_deeply merge_deeply( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    is_deeply merge_deeply( [ 1, 2 ], [ 3, 4, 5 ] ), [ 1, 2, 3, 4, 5 ];

    # hash
    $src = { a => 1, b => 2 };
    is_deeply merge_deeply( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    # hash/array complex
    $src = { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ] };
    undef $dst;
    is_deeply merge_deeply( $dst, $src ), $src;
    is_deeply $dst, $src;
    isnt \$dst, \$src;

    $dst = { b => 42, z => 999 };
    is_deeply merge_deeply( $dst, $src ),
        { a => [ 1, 2 ], b => [ 3, 4 ], c => [ 5, 6 ], z => 999 };
}

# test: apply_deeply
{
    my $func = sub {
        $_ += shift if defined $_;
    };

    my $t;

    is apply_deeply( undef, $func, 1 ), undef;

    $t = 1;
    is apply_deeply( $t, $func, 1 ), 2;
    is $t, 2;

    $t = [ 1, 2, 3 ];
    is_deeply apply_deeply( $t, $func, 1 ), [ 2, 3, 4 ];
    is_deeply $t, [ 2, 3, 4 ];

    $t = { a => 1, b => 2, c => 3, };
    is_deeply apply_deeply( $t, $func, 1 ), { a => 2, b => 3, c => 4, };
    is_deeply $t, { a => 2, b => 3, c => 4, };

    $t = { a => 1, b => [ 2, 3 ], c => 4, };
    is_deeply apply_deeply( $t, $func, 1 ),
        { a => 2, b => [ 3, 4 ], c => 5, };
    is_deeply $t, { a => 2, b => [ 3, 4 ], c => 5, };
}

# test: process_perl
{
    is process_perl( sub {'foo'} ), 'foo';
    is process_perl( sub { shift->{hoge} }, { hoge => 'fuga' } ), 'fuga';
    eval {
        process_perl( sub { die "fooo" } );
    };
    like $@, qr/^run code faild: reason=fooo/;
}

# test: process_perl_deeply
{
    my $elm = {
        foo => [ sub {"hoge"}, sub {"fuga"}, ],
        bar => sub   {shift},
    };
    is_deeply process_perl_deeply( $elm, 42 ),
        {
        foo => [ 'hoge', 'fuga', ],
        bar => 42
        };
    is_deeply $elm,
        {
        foo => [ 'hoge', 'fuga', ],
        bar => 42
        };

}

# test: commify
{
    is commify(100),       '100';
    is commify(1_000),     '1,000';
    is commify(1_999_999), '1,999,999';
}
