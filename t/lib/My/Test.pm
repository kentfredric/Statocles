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
      build_test_site build_test_site_apps
      build_temp_site
    )],
    'Statocles::Types' => [qw( DateTimeObj )],
    'My::Test::_Extras' => [qw( test_constructor test_pages )],
    sub { $Statocles::VERSION ||= 0.001; return }, # Set version normally done via dzil
);

package My::Test::_Extras;

$INC{'My/Test/_Extras.pm'} = 1;

require Exporter;
*import = \&Exporter::import;

use Test::Exception;
use Test::Deep;
use Test::More;

our @EXPORT_OK = qw( test_constructor test_pages );

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

sub test_pages {
    my ( $site, $app ) = ( shift, shift );
    require Mojo::DOM;
    require Scalar::Util;

    my %opt;
    if ( ref $_[0] eq 'HASH' ) {
        %opt = %{ +shift };
    }

    my %page_tests = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @pages = $app->pages;

    is scalar @pages, scalar keys %page_tests, 'correct number of pages';

    for my $page ( @pages ) {
        ok $page->DOES( 'Statocles::Page' ), 'must be a Statocles::Page';

        isa_ok $page->date, 'DateTime::Moonpig', 'must set a date';

        if ( !$page_tests{ $page->path } ) {
            fail "No tests found for page: " . $page->path;
            next;
        }

        my $output = $page->render( site => $site );

        # Handle filehandles from render
        if ( ref $output eq 'GLOB' ) {
            $output = do { local $/; <$output> };
        }
        # Handle Path::Tiny from render
        elsif ( Scalar::Util::blessed( $output ) && $output->isa( 'Path::Tiny' ) ) {
            $output = $output->slurp_raw;
        }

        if ( $page->path =~ /[.](?:html|rss|atom)$/ ) {
            my $dom = Mojo::DOM->new( $output );
            fail "Could not parse dom" unless $dom;
            subtest 'html content: ' . $page->path, $page_tests{ $page->path }, $output, $dom;
        }
        elsif ( $page_tests{ $page->path } ) {
            subtest 'text content: ' . $page->path, $page_tests{ $page->path }, $output;
        }
        else {
            fail "Unknown page: " . $page->path;
        }

    }

    ok !@warnings, "no warnings!" or diag join "\n", @warnings;
}

1;
