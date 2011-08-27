package ShionBackup::Config;

=head1 NAME

ShionBackup::Config

=cut

use strict;
use warnings;
use YAML::Syck;
use ShionBackup::Logger;

my $config = {};

=head1 DESCRIPTION

=head2 CLASS METHODS

=over 4

=item load

=cut

sub load {
    my $class = shift;
    my @files = @_;

    local $YAML::Syck::ImplicitUnicode = 1;
    local $YAML::Syck::UseCode         = 1;

    for my $file (@files) {
        my $data = eval { LoadFile($file) };
        if ($@) {
            die "$file: $@\n";
        }
        _merge_deep( $config, $data );
    }
    _preprocess_templates($config);

    # preprocess targets
    $config->{targets} = _preprocess_targets($config);

    DEBUG Dump($config) if IS_DEBUG;

    $config;
}

=back

=head2 CLASS METHODS

=over 4

=item config

=cut

sub config {
    shift;
    $config = shift if @_;
    $config;
}

=back

=head2 FUNCTIONS

=over 4

=item dump_config

=cut

sub dump_config {
    local $YAML::Syck::SortKeys = 1;
    Dump($config);
}

sub _preprocess_templates {
    my ( $config, $names ) = @_;
    $names //= [ keys %{ $config->{templates} } ];
    $names = [$names] unless ref $names eq 'ARRAY';

    for my $name (@$names) {
        DEBUG "name: $name";
        my $template = $config->{templates}{$name}{template} or next;
        DEBUG "has template: $name";
        _preprocess_templates( $config, $template );
        my $new_template;
        for my $t ( ref $template ? @$template : $template ) {
            DEBUG "merge template $t to $name";
            _merge_deep( $new_template, $config->{templates}{$t} );
        }
        $config->{templates}{$name}
            = _merge_deep( $new_template, $config->{templates}{$name} );
        delete $config->{templates}{$name}{template};
    }
    1;
}

sub _preprocess_targets {
    my ($config) = @_;

    my @targets;
    for my $t ( @{ $config->{targets} } ) {
        my $target;

        # merge args
        _merge_deep( $target->{args}, $config->{args} )
            if exists $config->{args};

        # process template
        if ( $t->{template} ) {
            for my $template (
                ref $t->{template} eq 'ARRAY'
                ? @{ $t->{template} }
                : $t->{template}
                )
            {
                _merge_deep( $target, $config->{templates}{$template} );
            }
        }
        _merge_deep( $target, $t );

        # normalize commands
        if ( ref $target->{commands} eq 'HASH' ) {
            $target->{commands} = [
                map { $target->{commands}{$_} }
                sort keys %{ $target->{commands} }
            ];
        }

        push @targets, $target;
    }
    \@targets;
}

sub _merge_deep {
    my $dstr     = \$_[0];
    my $src      = $_[1];
    my $src_type = ref($src);

    if ( $src_type eq 'ARRAY' ) {
        $$dstr = [] unless ref($$dstr) eq 'ARRAY';
        for ( my $i = 0; $i < @$src; ++$i ) {
            _merge_deep( $$dstr->[$i], $src->[$i] );
        }
    }
    elsif ( $src_type eq 'HASH' ) {
        $$dstr = {} unless ref($$dstr) eq 'HASH';
        for my $key ( keys %$src ) {
            _merge_deep( $$dstr->{$key}, $src->{$key} );
        }
    }
    else {
        $$dstr = $src;
    }
    $$dstr;
}

1;

=back

=head1 CONFIG STRUCTURE

 s3:
   baseurl: string or code
   id:      string
   secret:  string
 templates:
   TEMPLAGE_NAME:
     # using other templates (optional)
     template: TEMPLATE_NAME or [ TEMPLATE_NAME...]
 targets:
   -
   # upload filename
   filename: string

   # using templates (optional)
   template: TEMPLATE_NAME or [ TEMPLATE_NAME...]

   # dump commands (array or hash (sorted by keys))
   commands:
     - string or code

=cut
