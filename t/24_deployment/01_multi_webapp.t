use strict;
use warnings;

use WWW::Mechanize;
use Test::More;

my $starman_is_available = eval {require Starman};

unless ($starman_is_available) {
    plan( skip_all => "Starman is required for this test" );
} else {

    my $starman_pid     = "__starman.pid";
    my $starman_workers = 2;
    my $repeat_count    = 10;
    my $port            = 16321; # Random high socket
    my $app1_url        = "http://127.0.0.1:$port/app1";
    my $app2_url        = "http://127.0.0.1:$port/app2";

    my $app = <<'APP';
    use Dancer ":syntax";
    use Plack::Builder;
    require Dancer::App;
    require Dancer::Handler;

    my $app1 = sub {
        my $env = shift;
        Dancer::App->set_running_app('APP1');
        get "/" => sub { return "Hello App1"; };
        my $request = Dancer::Request->new(env => $env);
        Dancer->dance($request);
    };

    my $app2 = sub {
        my $env = shift;
        Dancer::App->set_running_app('APP2');
        get "/" => sub { return "Hello App2"; };
        my $request = Dancer::Request->new(env => $env);
        Dancer->dance($request);
    };

    builder {
        mount "/app1" => builder {$app1};
        mount "/app2" => builder {$app2};
    };
APP

    my @args = (
        '--pid', $starman_pid, '--port', $port, '-s', 'Starman', '--workers', $starman_workers,
        '-e', $app,
    );

    unless ( my $pid = fork() ) {
        system( "plackup", @args );
        exit;
    }
    sleep 3;    # wait until starman is up

    my $mech = WWW::Mechanize->new();
    $mech->get($app1_url);    # first access is /app1
    like( $mech->content(), qr/App1/, "Hello App1" );

    foreach my $i ( 1 .. $repeat_count ) {
        $mech->get($app2_url);    # continue access is /app2
        like( $mech->content(), qr/App2/, "Hello App2" );
    }

    done_testing;

    kill 1, `cat $starman_pid`;
    unlink $starman_pid;
    wait;
}
exit;

