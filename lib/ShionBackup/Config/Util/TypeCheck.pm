package ShionBackup::Config::Util::TypeCheck;

=head1 NAME

ShionBackup::Config::Util::TypeCheck - 型チェック

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Exporter);
use ShionBackup::Logger;

our @EXPORT = qw(
    TYPE_UNDEF TYPE_SCALAR TYPE_ARRAY TYPE_HASH TYPE_CODE TYPE_ANY
    match_type match_type_hash handle_unmatch
    MATCH_AND MATCH_VALUE MATCH_HASH
);
our @EXOIRT_OK = qw(
    MATCH_TYPE MATCH_TYPEDEEP
);

=head2 CONSTANTS

=over 4

=item TYPE_UNDEF

=item TYPE_SCALAR

=item TYPE_ARRAY

=item TYPE_HASH

=item TYPE_CODE

=item TYPE_ANY

=cut

for my $name (qw( UNDEF SCALAR ARRAY HASH CODE ANY )) {
    my $slot = __PACKAGE__ . "::TYPE_$name";
    no strict 'refs';
    *$slot = \&{"ShionBackup::Config::Util::TypeCheck::Matcher::TYPE_$name"};
}

=back

=head2 MATCHER

=over 4

=item MATCH_AND( $matcher, ... )

=item MATCH_VALUE( $value, ... )

=item MATCH_TYPE( $type, ... )

=item MATCH_TYPEDEEP( { $type => $matcher, ... } )

=item MATCH_HASH( { $key => $matcher, ... } )

=cut

for my $name (qw( And Value Type TypeDeep Hash )) {
    my $slot = __PACKAGE__ . "::MATCH_" . uc($name);
    no strict 'refs';
    *$slot = sub {
        "ShionBackup::Config::Util::TypeCheck::Matcher::$name"->new(@_);
    };
}

=back

=head2 FUNCTIONS

=over 4

=item match_type( $subject, \@types [, \@context]  )

=cut

sub match_type {
    my ($context) = splice @_, 2;
    ShionBackup::Config::Util::TypeCheck::Matcher->do_match(@_);
}

=item match_type_hash( $subject, \%types [, \@context] )

=cut

sub match_type_hash {
    my ($context) = splice @_, 2;
    my ( $subj, $types ) = @_;

    ShionBackup::Config::Util::TypeCheck::Matcher->do_match( $subj,
        MATCH_AND( TYPE_HASH(), MATCH_HASH(%$types) ) );
}

=item handle_unmatch BLOCK

=cut

sub handle_unmatch(&) {
    ShionBackup::Config::Util::TypeCheck::Matcher->catch_unmatch(@_);
}

package ShionBackup::Config::Util::TypeCheck::Unmatch;
use overload '""' => \&as_string;

sub new {
    my $class = shift;
    my %args  = @_;
    bless {
        context => $args{-Context} || [],
        message => defined $args{-Message} ? $args{-Message} : '',
        expect  => defined $args{-Expect}  ? $args{-Expect}  : '',
    }, $class;
}

sub context {
    shift->{context};
}

sub message {
    shift->{message};
}

sub expect {
    shift->{expect};
}

sub as_string {
    my $self = shift;
    "$self->{message}: expected=$self->{expect}, context="
        . join( '', @{ $self->{context} } ) . "\n";
}

package ShionBackup::Config::Util::TypeCheck::Matcher;
use ShionBackup::Logger;

sub TYPE_UNDEF  {0}
sub TYPE_SCALAR {''}
sub TYPE_ARRAY  {'ARRAY'}
sub TYPE_HASH   {'HASH'}
sub TYPE_CODE   {'CODE'}
sub TYPE_ANY    {'*'}

my $type_string_map = {
    TYPE_UNDEF()  => '<UNDEF>',
    TYPE_SCALAR() => 'SCALAR',
    TYPE_ARRAY()  => 'ARRAY',
    TYPE_HASH()   => 'HASH',
    TYPE_CODE()   => 'CODE',
    TYPE_ANY()    => '*',
};

sub type_string {
    my ( $class, @type ) = @_;
    for (@type) {
        $_ = $type_string_map->{$_} if exists $type_string_map->{$_};
    }
    wantarray ? @type : $type[0];
}

sub get_type {
    my ( $class, @subj ) = @_;
    my @type = map { defined $_ ? ref $_ : TYPE_UNDEF() } @subj;
    wantarray ? @type : $type[0];
}

sub get_type_string {
    my ( $class, @subj ) = @_;
    return $class->type_string( $class->get_type(@subj) );
}

sub safe_string {
    my ( $class, @subj ) = @_;
    for (@subj) {
        $_ = '<undef>' unless defined $_;
    }
    wantarray ? @subj : $subj[0];
}

sub do_match {
    my $class = shift;
    my ( $subj, $type ) = @_;
    my $typetype = $class->get_type($type);

    TRACE "(do_match) subject: ", $class->safe_string($subj)     if IS_TRACE;
    TRACE "typetype: ",           $class->type_string($typetype) if IS_TRACE;
    if ( $typetype eq TYPE_SCALAR() ) {
        $type = ( __PACKAGE__ . "::Type" )->new($type);
    }
    elsif ( $typetype eq TYPE_ARRAY() ) {
        $type = ( __PACKAGE__ . "::Type" )->new(@$type);
    }
    elsif ( $typetype eq TYPE_HASH() ) {
        $type = ( __PACKAGE__ . "::TypeDeep" )->new(%$type);
    }
    elsif ( eval { $type->isa(__PACKAGE__) } ) {
        ;
    }
    else {
        die "unsupported type: ", ref $type, "\n";
    }
    $type->match($subj) or die "match failed in ", ref $type;
}

sub throw {
    my $class = shift;
    die ShionBackup::Config::Util::TypeCheck::Unmatch->new(@_);
}

sub catch_unmatch {
    my $class = shift;
    my ( $unmatch, $other ) = @_;
    $other = sub { die shift }
        unless defined $other;

    if ($@) {
        my $e = $@;
        if (eval { $e->isa('ShionBackup::Config::Util::TypeCheck::Unmatch'); }
            )
        {
            $@ = $e;
            TRACE "Unmatch Exception: $@";
            $unmatch->($e);
            die $e;
        }
        else {
            $@ = $e;
            TRACE "Exception: $@";
            $other->($e);
        }
    }
}

package ShionBackup::Config::Util::TypeCheck::Matcher::And;
our @ISA = qw( ShionBackup::Config::Util::TypeCheck::Matcher );
use ShionBackup::Logger;

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub match {
    TRACE "match: and";
    my ( $self, $subj ) = @_;
    $self->do_match( $subj, $_ ) for @$self;
    1;
}

package ShionBackup::Config::Util::TypeCheck::Matcher::Value;
our @ISA = qw( ShionBackup::Config::Util::TypeCheck::Matcher );
use ShionBackup::Logger;

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub match {
    TRACE "match: value";
    my ( $self, $subj ) = @_;
    if ( !grep { $subj eq $_ || $_ eq $self->TYPE_ANY() } @$self ) {
        $self->throw(
            -Message => "'$subj' is not expected value",
            -Expect  => join '|',
            $self->safe_string(@$self)
        );
    }
    1;
}

package ShionBackup::Config::Util::TypeCheck::Matcher::Type;
our @ISA = qw( ShionBackup::Config::Util::TypeCheck::Matcher );
use ShionBackup::Logger;

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub match {
    TRACE "match: type";
    my ( $self, $subj ) = @_;
    my $subtype = $self->get_type($subj);
    if ( !grep { $subtype eq $_ || $_ eq $self->TYPE_ANY() } @$self ) {
        $self->throw(
            -Message => "'"
                . $self->type_string($subtype)
                . "' is not expected type",
            -Expect => join '|',
            $self->type_string(@$self)
        );
    }
    1;
}

package ShionBackup::Config::Util::TypeCheck::Matcher::TypeDeep;
our @ISA = qw( ShionBackup::Config::Util::TypeCheck::Matcher );
use ShionBackup::Logger;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub match {
    TRACE "match: typedeep";
    my ( $self, $subj ) = @_;
    my $subtype = $self->get_type($subj);
    if ( !exists $self->{$subtype} ) {
        $self->throw(
            -Message => "'"
                . $self->type_string($subtype)
                . "' is not expected type",
            -Expect => join '|',
            sort $self->type_string( keys %$self )
        );
    }

    my $nexttype = $self->{$subtype};
    if ( $subtype eq $self->TYPE_ARRAY() ) {
        TRACE "typedeep: type=array";
        my $count = 0;
        eval { ( ++$count, $self->do_match( $_, $nexttype ) ) for @$subj };
        $self->catch_unmatch( sub { unshift @{ shift->context }, "[$count]" }
        );
        return 1;
    }
    elsif ( $subtype eq $self->TYPE_HASH() ) {
        TRACE "typedeep: type=hash";
        for my $key ( keys %$subj ) {
            eval { $self->do_match( $subj->{$key}, $nexttype ) };
            $self->catch_unmatch(
                sub { unshift @{ shift->context }, "{$key}" } );
        }
        return 1;
    }
    else {
        TRACE "typedeep: type=other";
        return 1;
    }
}

package ShionBackup::Config::Util::TypeCheck::Matcher::Hash;
our @ISA = qw( ShionBackup::Config::Util::TypeCheck::Matcher );
use ShionBackup::Logger;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub match {
    TRACE "match: hash";
    my ( $self, $subj ) = @_;
    my $subtype = $self->get_type($subj);

    for my $key ( sort keys %$self ) {
        TRACE "check key '$key'" if IS_TRACE;
        eval { $self->do_match( $subj->{$key}, $self->{$key} ) };
        $self->catch_unmatch( sub { unshift @{ shift->context }, "{$key}" } );
        TRACE "check key '$key' ok." if IS_TRACE;
    }
    return 1;
}

1;
__END__

=back

=head1 AUTHOR

N. Yamamoto <nym@nym.jp>

