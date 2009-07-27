use Test::More tests => 5, import => ['!pass'];

{
    package Webapp;
    use Dancer;
    
    eval '$foo = 5;';
    ::ok($@, 'got an error because strict is on');
    ::like($@, qr/Global symbol \"\$foo\" requires explicit package name at/, 
        'got the right error');
    
    {
        my $warn;
        local $SIG{__WARN__} = sub { $warn = $_[0] };

        ::ok(!$warn, 'no warning yet');
                
        eval 'my $bar = 1 + "hello"';
        
        ::ok($warn, 'got a warning');
        ::like($warn, qr/Argument \"hello\" isn\'t numeric in addition \(\+\)/, 
            'got the right warning');
    }
}
