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
    },
    {
        mode => [ U, "second_decimal_odd" ],
        tests => [ [ '0.01' => U ], [ '0.02' => S ], [ '0.03' => U ], ],
    },
    {
        mode => [ U, "third_decimal_odd", T, "second_decimal_odd" ],
        tests => [ [ '0.010' => T ], [ '0.011' => U ], [ '0.020' => S ], [ '0.021' => U ], ],
    },
    {
        mode => [ U, "fourth_decimal_odd" ],
        tests => [ [ '123.0001' => U ], [ '12.0002' => S ], [ '1.0003' => U ], ],
    },
    {
        mode => [ U, "fifth_decimal_odd" ],
        tests => [ [ '123.00001' => U ], [ '12.00002' => S ], [ '1.00003' => U ], ],
    },
    {
        mode => [ U, "sixth_decimal_odd" ],
        tests => [ [ '123.000001' => U ], [ '12.000002' => S ], [ '1.000003' => U ], ],
    },
);

for my $c (@cases) {
    my ( $mode, $tests ) = @{$c}{qw/mode tests/};

    subtest "@$mode" => sub {
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

            is( $tzil->version, $version, "$version: dist version is set" );
            is( $meta->{release_status}, $status, "$version: release status '$status' in META" );
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
