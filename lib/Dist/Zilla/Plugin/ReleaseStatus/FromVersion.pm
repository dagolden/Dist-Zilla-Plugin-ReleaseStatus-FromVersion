use v5.10;
use strict;
use warnings;

package Dist::Zilla::Plugin::ReleaseStatus::FromVersion;
# ABSTRACT: Set release status from version number patterns

our $VERSION = '0.001';

use Moose;
use Moose::Util::TypeConstraints qw/enum/;
use version;

use constant {
    STABLE   => 'stable',
    TESTING  => 'testing',
    UNSTABLE => 'unstable',
};

my %RULES = (
    none               => sub { 0 },
    second_decimal_odd => _odd_digit_checker(2),
    third_decimal_odd  => _odd_digit_checker(3),
    fourth_decimal_odd => _odd_digit_checker(4),
    fifth_decimal_odd  => _odd_digit_checker(5),
    sixth_decimal_odd  => _odd_digit_checker(6),
    second_tuple_odd   => _odd_tuple_checker(2),
    third_tuple_odd    => _odd_tuple_checker(3),
    fourth_tuple_odd   => _odd_tuple_checker(4),
);

enum VersionMode => [ keys %RULES ];

has testing => (
    is      => 'ro',
    isa     => 'VersionMode',
    default => 'none',
);

has unstable => (
    is      => 'ro',
    isa     => 'VersionMode',
    default => 'none',
);

sub BUILD {
    my ($self) = @_;
    for my $type ( TESTING, UNSTABLE ) {
        my $rule = $self->$type;
        $self->logger->log_fatal("Unknown rule for '$type': $rule")
          unless $RULES{$rule};
    }
}

sub provide_release_status {
    my $self    = shift;
    my $version = version->new( $self->zilla->version );
    my ( $urule, $trule );
    if ( $urule = $RULES{ $self->unstable } and $urule->($version) ) {
        return UNSTABLE;
    }
    if ( $trule = $RULES{ $self->testing } and $trule->($version) ) {
        return TESTING;
    }
    else {
        return STABLE;
    }
}

#--------------------------------------------------------------------------#
# utility functions
#--------------------------------------------------------------------------#

sub _odd_digit_checker {
    my $pos = shift;
    return sub {
        my $version = shift;
        return if $version->is_qv;
        my ($fraction) = $version =~ m{\.(\d+)\z};
        return unless defined($fraction) && length($fraction) >= $pos;
        return substr( $fraction, $pos - 1, 1 ) % 2;
    };
}

sub _odd_tuple_checker {
    my $pos = shift;
    return sub {
        my $version = shift;
        return unless $version->is_qv;
        my $string = $version->normal;
        $string =~ s/^v//;
        my @tuples = split /\./, $string;
        return ( defined( $tuples[ $pos - 1 ] ) ? ( $tuples[ $pos - 1 ] % 2 ) : 0 );
    };
}

with 'Dist::Zilla::Role::ReleaseStatusProvider';

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage BUILD

=head1 SYNOPSIS

    use Dist::Zilla::Plugin::ReleaseStatus::FromVersion;

=head1 DESCRIPTION

This module might be cool, but you'd never know it from the lack
of documentation.

=head1 USAGE

Good luck!

=head1 SEE ALSO

=for :list
* Maybe other modules do related things.

=cut

# vim: ts=4 sts=4 sw=4 et tw=75:
