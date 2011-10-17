use strict;
use warnings;
use Test::More import => ['!pass'];

use Dancer ':syntax';
use Dancer::Test;

BEGIN { use_ok('Dancer::Exception', ':all'); }

set views => path( 't', '25_exceptions', 'views' );

{
    # halt in route
    my $v = 0;
    get '/halt_in_route' => sub {
        halt ({ error => 'plop' });
        $v = 1;
    };
    response_content_like( [ GET => '/halt_in_route' ], qr|Unable to process your query| );
    response_status_is( [ GET => '/halt_in_route' ], 500 => "We get a 500 status" );
    is ($v, 0, 'halt broke the workflow as intended');
}

{
    # halt in hook
    my $flag = 0;
    my $v = 0;
    hook before_template_render => sub {
        if ( 0 || ! $flag++ ) {
            status 500;
            halt ({ error => 'plop2' });
            $v = 1;
        }
    };

    get '/halt_in_hook' => sub {
        template 'index';
    };
    response_content_like( [ GET => '/halt_in_hook' ], qr|Unable to process your query| );
    is ($v, 0, 'halt broke the workflow as intended');
    $flag = 0;
    response_status_is( [ GET => '/halt_in_hook' ], 500 => "We get a 500 status" );
}

set error_template => "error.tt";

{
    # die in route
    get '/die_in_route' => sub {
        die "die in route";
    };
    
    response_content_like( [ GET => '/die_in_route' ], qr|MESSAGE: <h2>runtime error</h2><pre class="error">die in route| );
    response_content_like( [ GET => '/die_in_route' ], qr|EXCEPTION: die in route| );
    response_status_is( [ GET => '/die_in_route' ], 500 => "We get a 500 status" );
}

register_exception ('Test',
                    message_pattern => "test - %s",
                   );

{
    my $route_hook_executed = 0;
    my $handler_hook_executed = 0;

    # raise in route
    get '/raise_in_route' => sub {
        raise Test => 'plop';
    };

    hook on_route_exception => sub {
        my ($exception) = @_;
        $exception->isa('Dancer::Exception::Test');
        $route_hook_executed++;
    };

    hook on_handler_exception => sub {
        my ($exception) = @_;
        $exception->isa('Dancer::Exception::Test');
        $handler_hook_executed++;
    };

    response_content_like( [ GET => '/raise_in_route' ], qr|MESSAGE: <h2>runtime error</h2>| );
    my $e = "test - plop";
    response_content_like( [ GET => '/raise_in_route' ], qr|EXCEPTION: $e| );
    response_status_is( [ GET => '/raise_in_route' ], 500 => "We get a 500 status" );
    is($route_hook_executed, 3,"exception route hook has been called");
    is($handler_hook_executed, 3,"exception handler hook has been called");
}

{
    # die in hook
    my $flag = 0;
    hook after_template_render => sub {
        $flag++
          or die "die in hook";
    };
    get '/die_in_hook' => sub {
        template 'index', { foo => 'baz' };
    };
    $flag = 0;
    response_content_like( [ GET => '/die_in_hook' ], qr|MESSAGE: <h2>runtime error</h2>| );
    $flag = 0;
    response_content_like( [ GET => '/die_in_hook' ], qr|EXCEPTION: die in hook| );
    $flag = 0;
    response_status_is( [ GET => '/die_in_hook' ], 500 => "We get a 500 status" );
}

register_exception ('Generic',
                    message_pattern => "test message : %s",
                   );

{
    # raise in hook
    my $flag = 0;
    hook before_template_render => sub {
        $flag++
          or raise Generic => 'foo';
    };
    get '/raise_in_hook' => sub {
        template 'index', { foo => 'baz' };
    };
    route_exists [ GET => '/raise_in_hook' ];
    $flag = 0;
    response_content_like( [ GET => '/raise_in_hook' ], qr|MESSAGE: <h2>runtime error</h2>| );
    $flag = 0;
    response_content_like( [ GET => '/raise_in_hook' ], qr|EXCEPTION: test message : foo| );
    $flag = 0;
    response_status_is( [ GET => '/raise_in_hook' ], 500 => "We get a 500 status" );
}

done_testing();
