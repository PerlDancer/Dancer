use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer::Exception qw(:all);

ok(1, "load ok");

# test try/catch/continuation

{
    my $v1 = 0;
    eval { try { $v1 = 1 }; };
    ok(! $@);
    is($v1, 1);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1 } catch { $v1 = 2; }; };
    ok(! $@);
    is($v1, 1);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die "plop"; } catch { $v1 = 2; }; };
    ok(! $@);
    is($v1, 2);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die bless {}, 'Dancer::Continuation'; } catch { $v1 = 2; }; };
    my $e = $@;
    ok(defined $e);
    is($v1, 1);
    ok($e->isa('Dancer::Continuation'));
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die bless {}, 'Dancer::Continuation'; } catch { $v1 = 2; } continuation { $v1 = 3; }; };
    ok(! $@);
    is($v1, 3);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die bless {}, 'Dancer::Continuation'; } continuation { $v1 = 3; } catch { $v1 = 2; }; };
    ok(! $@);
    is($v1, 3);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die bless {}, 'plop'; } continuation { $v1 = 3; } catch { $v1 = 2; }; };
    ok(! $@);
    is($v1, 2);
}

{
    my $v1 = 0;
    eval { try { $v1 = 1; die "plop"; } continuation { $v1 = 3; } catch { $v1 = 2; }; };
    ok(! $@);
    is($v1, 2);
}

{
    my $registered = [ registered_exceptions ];
    is_deeply($registered, [ qw(Base Core Fatal Internal) ]);
}

register_exception ('InvalidCredentials',
                    message_pattern => "invalid credentials : %s",
                   );

register_exception ('InvalidPassword',
                    composed_from => [qw(Fatal InvalidCredentials)],
                    message_pattern => "wrong password",
                   );

register_exception ('InvalidLogin',
                    composed_from => [qw(Fatal InvalidCredentials)],
                    message_pattern => "wrong login (login was %s)",
                   );

register_exception ('HarmlessInvalidLogin',
                    composed_from => [qw(InvalidLogin)],
                    message_pattern => "ignored invalid login",
                   );

{
    my $registered = [ registered_exceptions ];
    is_deeply($registered, [
        qw(Base Core Fatal HarmlessInvalidLogin Internal InvalidCredentials InvalidLogin
           InvalidPassword )
    ]);
}

{
    my $v1 = 0;
    my $e;
    eval {
        try {
            $v1 = 1;
            raise InvalidLogin => 'douglas'
        } continuation {
            $v1 = 3;
        } catch {
            $e = shift;
            $v1 = 2;
        };
    };
    ok(! $@);
    is($e, 'fatal - invalid credentials : wrong login (login was douglas)');
    # check stringification works in other cases
    ok($e eq 'fatal - invalid credentials : wrong login (login was douglas)');
    ok('fatal - invalid credentials : wrong login (login was douglas)' eq $e);
    ok($e->does('InvalidLogin'));
    is($v1, 2);
}

done_testing;
