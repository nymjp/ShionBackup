#!perl -T

use Test::More;
use strict;
use warnings;

BEGIN {
    eval "use Test::MockObject; use Test::MockObject::Extends";
    plan skip_all =>
        "Test::MockObject required for testing ShionBackup::TargetProcesser"
        if $@;

    use_ok('ShionBackup::TargetProcesser');
}

use ShionBackup::Config::Target;
use ShionBackup::Uploader::Null;

sub create_target {
    my $target = ShionBackup::Config::Target->new;
    $target->merge(
        {   filename => 'testfile',
            command  => {
                0 => sub { print "string" },
                1 => sub { print "test:$_" while <> },
            },
        }
    );
    $target;
}

sub create_object {
    my $uploader = Test::MockObject::Extends->new('ShionBackup::Uploader');

 #Test::MockObject::Extends->new('ShionBackup::TargetProcesser', $uploader, );
    ShionBackup::TargetProcesser->new($uploader);
}

# test: new
{
    ok create_object;
}

# test: spawn_commands
{
    my $t  = create_object;
    my $fh = $t->spawn_commands(create_target)->output_fh;
    is scalar <$fh>, 'test:string';
}

# test: run && process_output
{
    my $t = create_object;
    my $u = $t->uploader;
    $u->set_true( 'upload', 'complete_upload' );
    $u->set_always( 'init_upload', 'abc' );

    local $ShionBackup::TargetProcesser::READ_UNIT = 5;

    # single upload
    {
        ok $t->run(create_target);

        my $f = $t->{work_fh};
        is_deeply [<$f>], ['test:string'];
        is_deeply [ $u->next_call ],
            [ 'upload', [ $u, {}, 'testfile', $t->{work_fh} ] ];
        ok !defined $u->next_call;
    }

    # part upload
    {
        my $tg = create_target;
        $tg->merge( { uploadsize_byte => 6 } );
        my @expect = ( 'test:strin', 'g' );
        $u->mock(
            upload_part => sub {
                is $_[1], 'abc';         # context
                is $_[2], 'testfile';    # context
                my $fh = $_[3];
                is( join( '', <$fh> ), shift @expect );
            }
        );
        ok $t->run($tg);

        my $fh = $t->{work_fh};
        is_deeply [ $u->next_call ],
            [ 'init_upload', [ $u, {}, 'testfile' ] ];
        is_deeply [ $u->next_call ],
            [ 'upload_part', [ $u, 'abc', 'testfile', $fh ] ];
        is_deeply [ $u->next_call ],
            [ 'upload_part', [ $u, 'abc', 'testfile', $fh ] ];
        is_deeply [ $u->next_call ],
            [ 'complete_upload', [ $u, 'abc', 'testfile' ] ];
        ok !defined $u->next_call;
    }

   # no output
    {
        my $tg = create_target;
        $tg->merge(
            {   command => {
                    1 => sub { exit 0 }
                }
            }
        );
        is $t->run($tg), 0;

        my $f = $t->{work_fh};
        is(join( '', <$f>), '');
        is_deeply [ $u->next_call ],
            [ 'upload', [ $u, {}, 'testfile', $t->{work_fh} ] ];
        ok !defined $u->next_call;
    }

    # fail command ( no output fail )
    {
        my $tg = create_target;
        $tg->merge(
            {   command => {
                    1 => sub { exit 1 }
                }
            }
        );
        eval { $t->run($tg) };
        like $@, qr/^some commands failed:/;
    }

    # fail command ( not success )
    {
        my $tg = create_target;
        $tg->merge(
            {   command => {
                    1 => sub { print "teststring"; exit 1 }
                }
            }
        );
        eval { $t->run($tg) };
        like $@, qr/^some commands failed:/;
    }
}

done_testing();
