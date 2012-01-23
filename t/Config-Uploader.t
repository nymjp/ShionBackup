#!perl -T

use Test::More 'no_plan';

BEGIN {
    use_ok('ShionBackup::Config::Uploader');
}

sub create_object {
    ShionBackup::Config::Uploader->new(@_);
}

# test: new
{
    my $t = create_object(
        {   class  => 'Null',
            id     => 'foo',
            secret => 'bar',
            url    => 'file://'
        }
    );
    isa_ok $t, 'ShionBackup::Config::SectionBase';
    isa_ok $t, 'ShionBackup::Config::Uploader';

    is_deeply $t->raw,
        {
        class  => 'Null',
        id     => 'foo',
        secret => 'bar',
        url    => 'file://'
        };
}

# test: check_raw
{
    my $t = create_object;

    ok $t->check_raw(
        {   class  => 'Null',
            id     => 'foo',
            secret => 'bar',
            url    => 'file://',
        }
    );

    # luck id
    eval { $t->check_raw( { class => 'Null', secret => 'bar' } ) };
    ok $@;

    eval { $t->check_raw( { class => 'Null', id => 'foo' } ) };
    ok $@;
}

# test: check_processed
{
    my $t = create_object;

    ok $t->check_processed(
        {   class  => 'Null',
            id     => 'foo',
            secret => 'bar',
            url    => 'file://',
        }
    );

    eval { $t->check_processed( { class => 'Null', secret => 'bar' } ) };
    ok $@;
}

# test: process_elements
{
    my $t = create_object;
    my $h = $t->process_elements(
        { class => 'Null', id => 'foo', secret => 'bar' } );
    is_deeply $h, { class => 'Null', id => 'foo', secret => 'bar' };
}
