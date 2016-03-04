package My::Test;

# ABSTRACT: Utilities for testing Statocles Tests

use strict;
use warnings;

use base 'Import::Base';

our @IMPORT_MODULES = (
    sub {
        # Disable spurious warnings on platforms that Net::DNS::Native does not
        # support. We don't use this much mojo
        $ENV{MOJO_NO_NDN} = 1;
        return;
    },
    strict => [],
    warnings => [],
    feature => [qw( :5.10 )],
    'Path::Tiny' => [qw( rootdir cwd )],
    'DateTime::Moonpig',
    'Statocles',
    qw( Test::More Test::Deep Test::Differences Test::Exception ),
    'Dir::Self' => [qw( __DIR__ )],
    'Path::Tiny' => [qw( path tempdir cwd )],
    'Statocles::Test' => [qw(
      test_pages build_test_site build_test_site_apps
      build_temp_site
    )],
    'Statocles::Types' => [qw( DateTimeObj )],
    'My::Test::_Extras' => [qw( test_constructor )],
    sub { $Statocles::VERSION ||= 0.001; return }, # Set version normally done via dzil
);

package My::Test::_Extras;

$INC{'My/Test/_Extras.pm'} = 1;

require Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw( test_constructor );

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default}  ? ( %{ $args{default} } )  : ();
    require Test::Builder;
    require Scalar::Util;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    $tb->subtest(
        $class . ' constructor' => sub {
            my $got    = $class->new(%required);
            my $want   = $class;
            my $typeof = do {
                    !defined $got                ? 'undefined'
                  : !ref $got                    ? 'scalar'
                  : !Scalar::Util::blessed($got) ? ref $got
                  : eval { $got->isa($want) } ? $want
                  :                             Scalar::Util::blessed($got);
            };
            $tb->is_eq( $typeof, $class,
                'constructor works with all required args' );

            if ( $args{required} ) {
                $tb->subtest(
                    'required attributes' => sub {
                        for my $key ( keys %required ) {
                            require Test::Exception;
                            &Test::Exception::dies_ok(
                                sub {
                                    $class->new(
                                        map { ; $_ => $required{$_} }
                                        grep { $_ ne $key } keys %required,
                                    );
                                },
                                $key . ' is required'
                            );
                        }
                    }
                );
            }

            if ( $args{default} ) {
                $tb->subtest(
                    'attribute defaults' => sub {
                        my $obj = $class->new(%required);
                        for my $key ( keys %defaults ) {
                            if ( ref $defaults{$key} eq 'CODE' ) {
                                local $_ = $obj->$key;
                                $tb->subtest(
                                    "$key default value" => $defaults{$key} );
                            }
                            else {
                                require Test::Deep;
                                Test::Deep::cmp_deeply( $obj->$key,
                                    $defaults{$key}, "$key default value" );
                            }
                        }
                    }
                );
            }

        }
    );
}
1;
