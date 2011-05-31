use 5.008005;
use ExtUtils::MakeMaker;

# ctags support
# run perl Makfefile.PL && make tags
sub MY::postamble {
    my $postamble = <<'MAKE_FRAG';
.PHONY: tags

tags:
	ctags -f tags --recurse --totals \
        --exclude=blib \
        --exclude=.git \
        --exclude='*.swp' \
        --languages=Perl --langmap=Perl:+.t 

author_test:
	RELEASE_TESTING=1 $(MAKE) test

MAKE_FRAG
}

WriteMakefile1(
    NAME         => 'Dancer',
    ABSTRACT     => "A minimal-effort oriented web application framework",
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/Dancer.pm',
    EXE_FILES    => ['script/dancer'],

    META_MERGE => {
        resources => {
            repository => 'http://github.com/sukria/Dancer',
            bugtracker => 'http://github.com/sukria/Dancer/issues',
            homepage   => 'http://perldancer.org/',
        },
    },

    BUILD_REQUIRES => {
        'Test::More'              => '0.94',
    },

    PREREQ_PM => {

        # non-core
        'LWP'                        => '0',
        'HTTP::Body'                 => '1.07', # needed for cleanup()
        'HTTP::Server::Simple::PSGI' => '0.11',
        'MIME::Types'                => '0',
        'URI'                        => '0',

        # core
        'File::Basename' => '0',
        'File::Spec'     => '0',
        'Encode'         => '0',
        'Time::HiRes'    => '0', # in core since 5.7
    },

    test      => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
    clean     => {FILES => "t/lib/sessions/*.yml logs/*.log t/*/logs/*" }

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

