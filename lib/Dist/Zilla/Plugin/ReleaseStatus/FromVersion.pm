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
    second_element_odd => _odd_tuple_checker(2),
    third_element_odd  => _odd_tuple_checker(3),
    fourth_element_odd => _odd_tuple_checker(4),
);

enum VersionMode => [ keys %RULES ];

=attr testing

Rule for setting status to 'testing'.  Must be one of the L</Status Rules>.

The default is C<none>.

=cut

has testing => (
    is      => 'ro',
    isa     => 'VersionMode',
    default => 'none',
);

=attr unstable

Rule for setting status to 'unstable'.  Must be one of the L</Status rules>.

This setting takes precedence over C<testing>.

The default is C<none>.

=cut

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

    $self->logger->log_fatal("Versions with underscore ('$version') are not supported")
      if $version =~ /_/;

    return
        $RULES{ $self->unstable }->($version) ? UNSTABLE
      : $RULES{ $self->testing }->($version)  ? TESTING
      :                                         STABLE;
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

=for Pod::Coverage BUILD STABLE TESTING UNSTABLE provide_release_status

=head1 SYNOPSIS

    # in dist.ini
    [ReleaseStatus::FromVersion]
    testing = third_decimal_odd

=head1 DESCRIPTION

This module tells L<Dist::Zilla> to set distribution's release status based
on its version number.

There are two attributes: C<testing> and C<unstable>.  Each is assigned a
string corresponding to a rule to apply to the distribution's version.
(See L</Status rules>)

If the C<unstable> rule is true, the status will be 'unstable'.  Otherwise,
if the C<testing> rule is true, the status will be 'testing'.  Otherwise,
the status will be 'stable'.

B<NOTE>: Version numbers with underscores, whether decimal or tuple, will
cause of fatal error.  This module B<replaces> underscore heuristics to
determine release status and is thus incompatible with such versions.

=head1 USAGE

Add C<[ReleaseStatus::FromVersion]> to your dist.ini and set the
C<testing> and/or C<unstable> attributes.  Keep in mind that
C<unstable> has the highest precedence.

=head2 Status rules

=head3 Default rule

The default rule 'none' is always false.

=head3 Decimal version rules

This set of rules apply only to "decimal versions" — versions that
that look like integers or floating point numbers.  They will be
false if applied to a version tuple.

The only decimal rules so far check a particular digit after the decimal
point and return true if the digit is odd:

    second_decimal_odd
    third_decimal_odd
    fourth_decimal_odd
    fifth_decimal_odd
    sixth_decimal_odd

For example, here is the 'fourth_decimal_odd' rule applied to two
version numbers:

    1.0100 — false
    1.0101 — true

=head3 Tuple version rules

This set of rules apply only to "tuple versions", aka "dotted-decimal
versions" — versions that that look like "v1", "v1.2", "v1.2.3" and so on.
They also apply to versions without the leading-v as long as there are more
than two decimal points, e.g. "1.2.3".  They will be false if applied to a
decimal version.

Tuple versions treat each decimal-separated value as an individual number.

The only tuple rules so far check a particular element of the tuple and
return true if the element is odd:

    second_element_odd
    third_element_odd
    fourth_element_odd

For example, here is the 'second_element_odd' rule applied to two
version numbers:

    v1.0.3 — false
    v1.1.3 — true

=head3 New rules

If you have an idea for a new rule, please look at how the existing rules
are implemented and open a Github issue or send a pull-request with your
idea.

=head1 EXAMPLE

Here is a somewhat contrived example demonstrating precedence:

    [ReleaseStatus::FromVersion]

    unstable = second_decimal_odd
    testing  = fourth_decimal_odd

    # results for different possible version

    1.0000 — stable
    1.0100 — unstable
    1.0101 — unstable
    1.0200 — stable
    1.0201 — testing
    1.0202 — stable

=cut

# vim: ts=4 sts=4 sw=4 et tw=75:
