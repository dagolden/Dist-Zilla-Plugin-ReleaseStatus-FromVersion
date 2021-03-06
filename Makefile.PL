use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.17;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Set release status from version number patterns",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Dist-Zilla-Plugin-ReleaseStatus-FromVersion",
  "LICENSE" => "apache",
  "MIN_PERL_VERSION" => "5.010000",
  "NAME" => "Dist::Zilla::Plugin::ReleaseStatus::FromVersion",
  "PREREQ_PM" => {
    "Dist::Zilla::Role::ReleaseStatusProvider" => 0,
    "Moose" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "constant" => 0,
    "strict" => 0,
    "version" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "JSON::MaybeXS" => 0,
    "Test::DZil" => 0,
    "Test::More" => "0.96"
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Dist::Zilla::Role::ReleaseStatusProvider" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "JSON::MaybeXS" => 0,
  "Moose" => 0,
  "Moose::Util::TypeConstraints" => 0,
  "Test::DZil" => 0,
  "Test::More" => "0.96",
  "constant" => 0,
  "strict" => 0,
  "version" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
