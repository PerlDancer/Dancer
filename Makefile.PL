use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Dancer',
    VERSION_FROM => 'lib/Dancer.pm',
    PREREQ_PM => {
        'HTTP::Server::Simple' => '0.38',
    },
    ABSTRACT => "A minimal-effort oriented web application framework",
    test => {TESTS => join( ' ', glob( 't/*.t' ))},
);
