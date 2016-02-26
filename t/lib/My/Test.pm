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

use Test::Exception;
use Test::Deep;
use Test::More;

our @EXPORT_OK = qw( test_constructor );

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default} ? ( %{ $args{default} } ) : ();

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $class . ' constructor' => sub {
        isa_ok $class->new( %required ), $class,
            'constructor works with all required args';

        if ( $args{required} ) {
            subtest 'required attributes' => sub {
                for my $key ( keys %required ) {
                    dies_ok {
                        $class->new(
                            map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                        );
                    } $key . ' is required';
                }
            };
        }

        if ( $args{default} ) {
            subtest 'attribute defaults' => sub {
                my $obj = $class->new( %required );
                for my $key ( keys %defaults ) {
                    if ( ref $defaults{ $key } eq 'CODE' ) {
                        local $_ = $obj->$key;
                        subtest "$key default value" => $defaults{ $key };
                    }
                    else {
                        cmp_deeply $obj->$key, $defaults{ $key }, "$key default value";
                    }
                }
            };
        }

    };
}


1;
