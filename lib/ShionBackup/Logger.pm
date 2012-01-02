package ShionBackup::Logger;

=head1 NAME

ShionBackup::Logger

=cut

use strict;
use warnings;
use FileHandle;
use Exporter 'import';
@ShionBackup::Logger::EXPORT
    = qw( LOG_ALL LOG_TRACE LOG_DEBUG LOG_INFO LOG_WARN LOG_DEBUG
    TRACE DEBUG INFO WARN ERROR FATAL
    IS_TRACE IS_DEBUG IS_INFO IS_WARN );

open my $logfh, '>&', \*STDOUT;
$logfh->autoflush(1);
our $LOG_FH            = $logfh;
our $LOG_LEVEL         = LOG_INFO();
our $TIMESTAMP_ENABLED = 0;

=head1 DESCRIPTION

=head2 LOG LEVELS

=over 4

=item LOG_ALL

=item LOG_TRACE

=item LOG_DEBUG

=item LOG_INFO

=item LOG_WARN

=item LOG_ERROR

=item LOG_FATAL

=cut

sub LOG_ALL   {0}
sub LOG_TRACE {1}
sub LOG_DEBUG {10}
sub LOG_INFO  {100}
sub LOG_WARN  {1000}
sub LOG_ERROR {10000}
sub LOG_FATAL {99999}

sub _LOG {
    my $level = shift;
    my $fh
        = ( @_ && ref( $_[0] ) eq 'GLOB' )
        ? shift
        : $LOG_FH;
    my @out = ( "[$level] ", @_ );
    if ($TIMESTAMP_ENABLED) {
        unshift @out, scalar localtime, ' ';
    }
    print $fh @out, "\n";
}

=back

=head2 LOG FUNCTIONS

=over 4

=item TRACE

=item IS_TRACE

=item DEBUG

=item IS_DEBUG

=item INFO

=item IS_INFO

=item WARN

=item IS_WARN

=item ERROR

=item IS_ERROR

=item FATAL

=item IS_FATAL

=cut

for my $field (qw[ TRACE DEBUG INFO WARN ERROR FATAL ]) {
    my $slot_log = __PACKAGE__ . "::$field";
    my $slot_is  = __PACKAGE__ . "::IS_$field";
    no strict 'refs';
    my $level = &{"LOG_$field"};
    *$slot_log = sub {
        return if $LOG_LEVEL > $level;
        _LOG( $field, @_ );
    };
    *$slot_is = sub {
        return if $LOG_LEVEL > $level;
        1;
    };
}

=item set_log_level

=cut

sub set_log_level {
    shift if ref $_[0];
    $LOG_LEVEL = shift;
}

1;

=back

=cut
