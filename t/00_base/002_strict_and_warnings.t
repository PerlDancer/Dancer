use Test::More tests => 10, import => ['!pass'];

{
    package Webapp;
    use Dancer ':syntax';

    # strict
    eval '$foo = 5;';
    ::ok($@, 'got an error because strict is on');
    ::like $@, qr/Global symbol "\$foo" requires explicit package name/,
        'got the right error';

    # checking warnings are on by default
    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, 'no warning yet');
                
        eval 'my $bar = 1 + "hello"';
        
        ::ok($warn, 'got a warning - default');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, 
            'got the right warning');
    }

    # check that we can disable it
    {
        # setting import_warnings => 0;
        #        
        # Since we're importing warnings in Dancer.pm as documented,
        # no warnings; should be used instead of import_warnings;
        no warnings;

        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok( !$warn, 'no warnings yet' );

        eval 'my $bar = 1 + "hello"';

        ::ok( !$warn, 'no warnings now either' );
    }

    # check that we can enable it
    {
        setting global_warnings => 1;

        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, 'no warning yet');

        eval 'my $bar = 1 + "hello"';

        ::ok($warn, 'got a warning - after enabling import');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/,
            'got the right warning');
    }

}
