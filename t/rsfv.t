use 5.006;
use strict;
use warnings;
use Test::More 0.96;
use JSON::MaybeXS;

use Test::DZil;

use constant {
    S => 'stable',
    T => 'testing',
    U => 'unstable',
};

my @cases = (
    {
        mode => [ T, "second_decimal_odd" ],
        tests => [ [ '0.01' => T ], [ '0.02' => S ], [ '0.03' => T ], ],
    }
);

for my $c (@cases) {
    my ( $mode, $tests ) = @{$c}{qw/mode tests/};

    subtest sprintf( "%s = %s", @$mode ) => sub {
        foreach my $t (@$tests) {
            my ( $version, $status ) = @$t;
            my $tzil = Builder->from_config(
                { dist_root => 'corpus/DZ' },
                {
                    add_files => {
                        'source/dist.ini' => simple_ini(
                            { version => $version }, 'GatherDir',
                            'MetaJSON', [ 'ReleaseStatus::FromVersion' => {@$mode} ]
                        ),
                    },
                },
            );

            $tzil->build;

            my $meta = decode_json( $tzil->slurp_file('build/META.json') );
            my $tar  = $tzil->archive_filename;

            is( $tzil->version,          $version, "$version: dist version is set" );
            is( $meta->{release_status}, $status,  "$version: release status set in META" );
            if ( $status eq S ) {
                unlike( $tar, qr/-TRIAL/, "$version: archive does not have -TRIAL" );
            }
            else {
                like( $tar, qr/-TRIAL/, "$version: archive has -TRIAL" );
            }
        }
    };
}

done_testing;
# COPYRIGHT
