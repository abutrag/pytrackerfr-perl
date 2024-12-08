use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'pytrackerfr',
    VERSION      => '1.0.0',
    AUTHOR       => 'abutrag <a.butragueno@eulerian.com>',
    ABSTRACT     => "Outil de génération d'URLs de tracking Eulerian.",
    LICENSE      => 'MIT',
    PREREQ_PM    => {
        'Text::CSV'    => 1.32,
        'URI::Escape'  => 3.31,
    },
    EXE_FILES    => ['main.pl'],
    META_MERGE   => {
        resources => {
            homepage    => 'https://github.com/abutrag/pytrackerfr',
        },
    },
    MIN_PERL_VERSION => '5.010',
);