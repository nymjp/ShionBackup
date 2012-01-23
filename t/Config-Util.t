#!perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Config::Util');
}

# test: expand_arg
{
    my $t = \&ShionBackup::Config::Util::expand_arg;

    my $args = { str1 => "hoge", str2 => "foo" };
    is 'foohogebar', $t->( $args, 'foo${str1}bar' );
    is 'foo$bar',    $t->( $args, 'foo${$}bar' );
    is 'foobar',     $t->( $args, 'foo${nokey}bar' );
    is 'hogefoo',    $t->( $args, '${str1}${str2}' );
    is( 'foohogebar|hogefoofuga',
        join '|',
        $t->(
            {   str1 => "hoge",
                str2 => 'foo'
            },
            'foo${str1}bar',
            'hoge${str2}fuga'
        )
    );

    is 'hogefuga', $t->( $args, '${str1:>fuga}' );
    is 'fugahoge', $t->( $args, '${str1:<fuga}' );
    is '',         $t->( $args, '${nokey:>fuga}' );
}

