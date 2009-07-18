use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Dancer',
    VERSION_FROM => 'lib/Dancer.pm',
    PREREQ_PM => {
        'CGI'                  => '0',
        'HTTP::Server::Simple' => '0.36',
        'Test::More'           => '0',
    },
    ABSTRACT => "A minimal-effort oriented web application framework",
    test => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
);
