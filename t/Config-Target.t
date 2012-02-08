#!perl -T

use Test::More;
use strict;
use warnings;

BEGIN {
    use_ok('ShionBackup::Config::Target');
}

use ShionBackup::Logger;

#ShionBackup::Logger::set_log_level(LOG_ALL);

sub create_object {
    ShionBackup::Config::Target->new(@_);
}

use ShionBackup::Config::Templates;
my $tmpl = ShionBackup::Config::Templates->new;
$tmpl->merge(
    {   foo => { filename => 'foo', arg => { foo => 'fooval' } },
        bar => {
            filename => 'bar',
            arg      => {
                bar => sub {'barval'}
            },
            template => 'foo'
        },
        lp1 => {
            filename => 'loop1',
            arg      => { klp => 'vlp1' },
            template => 'lp2'
        },
        lp2 => {
            filename => 'loop2',
            arg      => { klp => 'vlp2' },
            template => 'lp1'
        },
        lps => {
            filename => 'loops',
            arg      => { klp => 'vlps' },
            template => 'lps'
        },
    }
);

# test: new
{
    isa_ok create_object( $tmpl, {} ), 'ShionBackup::Config::Target';
}

# test: process_elements
{
    my $t = create_object($tmpl);
    {
        my $conf = $t->process_elements( { filename => 'me', } );
        is_deeply $conf,
            {
            filename        => 'me',
            uploadsize_byte => undef,
            template        => [],
            arg             => {},
            command         => {},
            };
    }
    {
        my $conf = $t->process_elements(
            {   filename   => 'me',
                template   => 'bar',
                uploadsize => 2,
            }
        );
        is $conf->{arg}{foo}, 'fooval';
        is $conf->{arg}{bar}, 'barval';
        is $conf->{uploadsize_byte}, 2_000_000;
    }

    # loop
    {
        my $conf = $t->process_elements(
            {   filename => 'me',
                template => 'lp1'
            }
        );
        is scalar keys %{ $conf->{arg} }, 1;
        is $conf->{arg}{klp}, 'vlp1';
        is_deeply $conf->{template}, [ 'lp1', 'lp2', 'lp1' ];
    }

    # loop(self)
    {
        my $conf = $t->process_elements(
            {   filename => 'me',
                template => 'lps'
            }
        );
        is scalar keys %{ $conf->{arg} }, 1;
        is $conf->{arg}{klp}, 'vlps';
        is_deeply $conf->{template}, [ 'lps', 'lps' ];
    }
}

# test: _process_arg_code
{
    my $t = create_object($tmpl);

    my $code_foo = sub {"foocode"};
    my $code_bar = sub {"barcode"};
    is_deeply(
        $t->_process_arg_code(
            {   arg     => { foo => $code_foo, },
                command => { bar => $code_bar, },
            }
        ),
        { arg => { foo => "foocode" }, command => { bar => $code_bar } }
    );
}

# test: _process_command_arg
{
    my $t = create_object($tmpl);

    {
        my $hash = $t->_process_command_arg(
            {   arg     => { foo => 'bar' },
                command => [ 'hoge ${foo} fuga', ],
            }
        );
        is $hash->{command}[0], 'hoge bar fuga';
    }

    {
        my $hash = $t->_process_command_arg(
            {   arg     => { foo  => 'bar' },
                command => { '00' => 'hoge ${foo} fuga', },
            }
        );
        is $hash->{command}{'00'}, 'hoge bar fuga';
    }
}

# test: d/a methods
{
    my $t = create_object(
        $tmpl,
        {   filename   => 'hoge',
            uploadsize => 42,
            arg        => { hoge => 'fuga' },
            template   => 'bar',
            command    => [ 'foo', 'bar', ],
        }
    );
    is $t->arg->{hoge}, 'fuga';
    is_deeply $t->template, [ 'foo', 'bar' ];
    is_deeply $t->command,  [ 'foo', 'bar' ];

    is $t->uploadsize_byte, 42_000_000;
}

# test: command_array
{
    {
        my $t = create_object( $tmpl,
            { filename => 'a', command => [ 'foo', 'bar' ], } );
        is_deeply $t->command_array, [ 'foo', 'bar' ];
    }
    {
        my $t = create_object( $tmpl,
            { filename => 'a', command => { '02' => 'foo', '01' => 'bar' }, }
        );
        is_deeply $t->command_array, [ 'bar', 'foo' ];
    }
}

done_testing();
