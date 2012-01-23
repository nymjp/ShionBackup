#!perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Config::Templates');
}

sub create_object {
    ShionBackup::Config::Templates->new();
}

# test: new
{
    isa_ok create_object, 'ShionBackup::Config::Templates';
}

# test: merge
{
    my $t = create_object;
    $t->merge(
        {   foo => { arg => { a => 'foo' } },
            bar => { arg => { a => 'bar' } },
        }
    );

    is $t->get('foo')->processed->{arg}{a}, 'foo';
    is $t->get('bar')->processed->{arg}{a}, 'bar';
    ok !defined $t->get('hoge');
}

# test: d/a method
{
    my $t = create_object;
    $t->merge(
        {   foo => { arg => { a => 'foo' } },
            bar => { arg => { a => 'bar' } },
        }
    );

    is_deeply $t->raw,
        {
        foo => { arg => { a => 'foo' } },
        bar => { arg => { a => 'bar' } },
        };
    ok exists $t->processed->{foo};
    ok exists $t->processed->{bar};
}
