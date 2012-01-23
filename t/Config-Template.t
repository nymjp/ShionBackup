#!perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Config::Template');
}

sub create_object {
    ShionBackup::Config::Template->new(@_);
}

# test: new
{
    my $t = create_object( { foo => 'bar' } );
    isa_ok $t, 'ShionBackup::Config::SectionBase';
    isa_ok $t, 'ShionBackup::Config::Template';
    is $t->raw->{foo}, 'bar';
}

# test: check_raw
{
    my $t = create_object;
    ok $t->check_raw( {} );
    ok $t->check_raw( { template => 'foo' } );
    ok $t->check_raw( { template => [ 'foo', 'bar' ] } );
}

# test: process_elements
{
    my $t = create_object();
    is_deeply( $t->process_elements( { template => 'foo' } ),
        { template => ['foo'], } );

}

# test: check_processed
{
    my $t = create_object;

    ok $t->check_processed(
        {   arg      => {},
            template => ['foo'],
            command  => {},
        }
    );
}

# test: d/a methods
{
    my $t = create_object(
        {   uploadsize => 42,
            arg        => { hoge => 'fuga' },
            template   => 'bar',
            command    => [ 'foo', 'bar', ],
        }
    );
    is_deeply $t->template, ['bar'];
}
