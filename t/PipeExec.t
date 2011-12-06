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
        $fh = $t->run( 'cat -n', $fh );
        like( scalar <$fh>, qr(^\s+1\s+hoge$) );
        $t->check_status;
    }

    # array
    {
        my $fh;
        $fh = $t->run( [qw(echo hoge)] );
        $fh = $t->run( 'cat -n', $fh );
        like( scalar <$fh>, qr(^\s+1\s+hoge$) );
        $t->check_status;
    }

    # array
    {
        my $fh;
        $fh = $t->run( sub { print shift }, undef, "hoge" );
        $fh = $t->run( 'cat -n', $fh );
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

# test: _process_args
{
    my $t = \&ShionBackup::PipeExec::_process_args;

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
    is '', $t->( $args, '${nokey:>fuga}' );
}
