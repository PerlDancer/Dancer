package main;
use strict;
use warnings;
use Test::More import => ['!pass'];

BEGIN {
    use Dancer;

    get '/server_error' => sub {
        send_error "default server error";
    };

    get '/server_error/:code' => sub {
        my $code = params->{code};
        send_error "server error $code" => $code;
    };

    get '/client_error' => sub {
        send_client_error "default client error";
    };

    get '/client_error/:code' => sub {
        my $code = params->{code};
        send_client_error "client error $code" => $code;
    };
}

use Dancer::Test;
use Data::Dumper;

sub _test_response {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %args = @_;
    my $path = $args{path};
    my $expected_status = $args{expected_status};
    my $expected_messages = $args{expected_messages};
    my $not_expected_messages = $args{not_expected_messages};
    my ($description, $description_add) = @{$args{description}};

    subtest "$description $description_add" => sub {
        plan tests => 1+@$expected_messages+@$not_expected_messages;

        my $response = dancer_response(GET => $path);
#        note("response for $path $description_add: ".Data::Dumper->Dump([$response], ['response']));
    
        is $response->{status}, $expected_status,
            "response status for $path should be $expected_status $description_add";
 
        foreach my $expected_message (@$expected_messages) {
            like $response->{content}, qr/\Q$expected_message\E/,
                "response content for $path should include \"$expected_message\" $description_add";
        }
 
        foreach my $not_expected_message (@$not_expected_messages) {
            unlike $response->{content}, qr/\Q$not_expected_message\E/,
                "response content for $path should not include \"$not_expected_message\" $description_add";
        }
    };
}


sub _test_errors {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my %args = @_;
    my ($description, $description_add) = @{$args{description}};

    my $do_test_response = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my %args = @_;

        my @expected_messages;
        my @not_expected_messages;

        my $expect_messages = sub {
            my $is_expected = shift;
            if ($is_expected) {
                push @expected_messages, @_;
            } else {
                push @not_expected_messages, @_;
            }
        };

        my $show_app_error = $args{show_errors} || $args{is_client_error};

        $expect_messages->($show_app_error,
            $args{error_message});

        $expect_messages->(!$args{serialized},
            "Error ".$args{expected_status});

        $expect_messages->(!$show_app_error && $args{serialized},
            'An internal error occured');

        $expect_messages->($args{show_errors} && !$args{serialized},
            'Stack', '11_send_error.t');

        _test_response(
            %args,
            expected_messages => [@expected_messages],
            not_expected_messages => [@not_expected_messages],
        );
    };

    subtest "$description $description_add" => sub {
        plan tests => 4;

        $do_test_response->(
            %args,
            path => '/server_error',
            expected_status => 500,
            is_client_error => 0,
            error_message => 'default server error',
            description => ['default server error', $description_add],
        );

        $do_test_response->(
            %args,
            path => '/server_error/789',
            expected_status => 789,
            is_client_error => 0,
            error_message => 'server error 789',
            description => ['server error 789', $description_add],
        );

        $do_test_response->(
            %args,
            path => '/client_error',
            expected_status => 400,
            is_client_error => 1,
            error_message => 'default client error',
            description => ['default client error', $description_add],
        );

        $do_test_response->(
            %args,
            path => '/client_error/678',
            expected_status => 678,
            is_client_error => 1,
            error_message => 'client error 678',
            description => ['client error 678', $description_add],
        );
    };
}


plan tests => 4;


Dancer::App->current->setting(show_errors => 1);

_test_errors(
    show_errors => 1,
    serialized => 0,
    description => ['errors', 'with show_errors = 1'],
);


Dancer::App->current->setting(show_errors => 0);

_test_errors(
    show_errors => 0,
    serialized => 0,
    description => ['errors', 'with show_errors = 0'],
);


SKIP: {
    skip 'JSON is needed to run this test', 2
        unless Dancer::ModuleLoader->load('JSON');

    Dancer::App->current->setting(serializer => 'JSON', show_errors => 1);

    _test_errors(
        show_errors => 1,
        serialized => 1,
        description => ['errors', 'with serializer and show_errors = 1'],
    );


    Dancer::App->current->setting(serializer => 'JSON', show_errors => 0);

    _test_errors(
        show_errors => 0,
        serialized => 1,
        description => ['errors', 'with serializer and show_errors = 0'],
    );
}


1;
