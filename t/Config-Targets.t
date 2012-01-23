#!perl -T

use Test::More 'no_plan';
use strict;
use warnings;

BEGIN {
    use_ok('ShionBackup::Config::Targets');
}

use ShionBackup::Config::Templates;
my $tmpl = ShionBackup::Config::Templates->new;
$tmpl->merge(
    {   foo => {
            arg     => { foo  => 'fooval', },
            command => { '01' => 'true', },
        },
    }
);

sub create_object {
    ShionBackup::Config::Targets->new($tmpl);
}

# test: new
{
    my $t = create_object;
    isa_ok $t, 'ShionBackup::Config::Targets';
}

# test: merge, raw, processed
{
    my $t = create_object;

    ok $t->merge(
        [   {   filename => 'hoge',
                template => 'foo',
            },
        ]
    );

    is_deeply $t->raw,
        [
        {   filename => 'hoge',
            template => 'foo',
        }
        ];
    is scalar @{ $t->processed }, 1;
    is_deeply $t->processed->[0]{arg}, { foo => 'fooval', };
}
