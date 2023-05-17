use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name         => 'Get::Article',
    license             => 'gpl_3',
    dist_author         => q{Kueppo Tcheukam <tcheukueppo@tutanota.com>},
    dist_version_from   => 'lib/Get/Article.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    add_to_cleanup     => [ 'Get-Article-*' ],
);

$builder->create_build_script();
