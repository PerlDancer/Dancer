use ExtUtils::MakeMaker;

WriteMakefile1(
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/sukria/Dancer',
        },
    },
    #BUILD_REQUIRES => {
    #},

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

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

