#!perl -T

use Test::More 'no_plan';
local $ENV{PATH} = '/bin';

BEGIN {
    use_ok('ShionBackup::PipeExec');
}

sub create_object {
    ShionBackup::PipeExec->new();
}

# test: run
{
    my $t = create_object;

    # str
    {
        my $fh;
        $fh = $t->run('echo hoge');
        $fh = $t->run('cat -n');
        my $output_fh = $t->output_fh;
        my $output    = scalar <$output_fh>;
        like( $output, qr(^\s+1\s+hoge$) );
        $t->check_status;
    }

    # array
    {
        my $fh;
        $fh = $t->run( [qw(echo hoge)] );
        $fh = $t->run( 'cat -n', {}, $fh );
        like( scalar <$fh>, qr(^\s+1\s+hoge$) );
        $t->check_status;
    }

    # array
    {
        my $fh;
        $fh = $t->run( sub { print shift }, "hoge" );
        $fh = $t->run( 'cat -n', {}, $fh );
        like( scalar <$fh>, qr(^\s+1\s+hoge$) );
        $t->check_status;
    }
}

# test: check_status
{
    my $t = create_object;

    $t->run('false');
    eval { $t->check_status; };
    like( $@, qr(^some commands failed:) );
}
