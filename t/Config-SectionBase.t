#!perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Config::SectionBase');
}

sub create_object {
    ShionBackup::Config::SectionBase->new(@_);
}

# test: new
{
    my $t = create_object;
    isa_ok $t, 'ShionBackup::Config::SectionBase';

    $t = create_object( { foo => 'bar' } );
    is $t->raw->{foo}, 'bar';
}

# test: merge
{
    $t = create_object( { foo => 'bar' } );
    $t->merge( { hoge => 'fuga' } );

    is $t->raw->{foo},  'bar';
    is $t->raw->{hoge}, 'fuga';
}

