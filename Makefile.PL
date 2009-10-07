use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Dancer',
    VERSION_FROM => 'lib/Dancer.pm',
    PREREQ_PM => {
        'CGI'                    => '0',
        'HTTP::Server::Simple'   => '0.34',
        'File::Basename'         => '0',
        'File::Spec'             => '0',
        'File::MimeInfo::Simple' => '0',
        'Template'               => '0',
        'Test::Requires'         => '0',
        'Test::More'             => '0',
        'Test::MockObject'       => '0',
        'Exception::Class'       => '0',
    },
    EXE_FILES => ['script/dancer'],
    ABSTRACT => "A minimal-effort oriented web application framework",
    test => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
);
