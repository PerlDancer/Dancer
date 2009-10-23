use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Dancer',
    VERSION_FROM => 'lib/Dancer.pm',
    PREREQ_PM => {
        'CGI'                    => '0',
        'HTTP::Server::Simple'   => '0.34',
        'Exception::Class'       => '0',
        'File::Basename'         => '0',
        'File::Spec'             => '0',
        'Test::More'             => '0',
        'Test::MockObject'       => '0',

# The following modules are needed by a few tests 
# but are not mandatory
#        'Test::Requires'         => '0',
#        'YAML'                   => '0',
#        'LWP'                    => '0',
    },
    EXE_FILES => ['script/dancer'],
    ABSTRACT => "A minimal-effort oriented web application framework",
    test => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
);
