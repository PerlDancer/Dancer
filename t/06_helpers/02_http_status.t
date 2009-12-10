use Test::More import => ['!pass'];

use Dancer::HTTP 'status';

my @tests = (
    {status => 'ok', expected => qr/200 OK/ },
    {status => '200', expected => qr/200 OK/ },
    {status => 'created', expected => qr/201 Created/ },
    {status => '201', expected => qr/201 Created/ },
    {status => 'accepted', expected => qr/202 Accepted/ },
    {status => '202', expected => qr/202 Accepted/ },
    {status => 'no_content', expected => qr/204 No Content/ },
    {status => '204', expected => qr/204 No Content/ },
    {status => 'reset_content', expected => qr/205 Reset Content/ },
    {status => '205', expected => qr/205 Reset Content/ },
    {status => 'partial_content', expected => qr/206 Partial Content/ },
    {status => '206', expected => qr/206 Partial Content/ },

    {status => 'moved_permanently', expected => qr/301 Moved Permanently/ },
    {status => '301', expected => qr/301 Moved Permanently/ },
    {status => 'found', expected => qr/302 Found/ },
    {status => '302', expected => qr/302 Found/ },
    {status => 'not_modified', expected => qr/304 Not Modified/ },
    {status => '304', expected => qr/304 Not Modified/ },
    {status => 'switch_proxy', expected => qr/306 Switch Proxy/ },
    {status => '306', expected => qr/306 Switch Proxy/ },

    {status => 'bad_request', expected => qr/400 Bad Request/ },
    {status => '400', expected => qr/400 Bad Request/ },
    {status => 'unauthorized', expected => qr/401 Unauthorized/ },
    {status => '401', expected => qr/401 Unauthorized/ },
    {status => 'payment_required', expected => qr/402 Payment Required/ },
    {status => '402', expected => qr/402 Payment Required/ },
    {status => 'forbidden', expected => qr/403 Forbidden/ },
    {status => '403', expected => qr/403 Forbidden/ },
    {status => 'not_found', expected => qr/404 Not Found/ },
    {status => '404', expected => qr/404 Not Found/ },
    {status => 'method_not_allowed', expected => qr/405 Method Not Allowed/ },
    {status => '405', expected => qr/405 Method Not Allowed/ },
    {status => 'not_acceptable', expected => qr/406 Not Acceptable/ },
    {status => '406', expected => qr/406 Not Acceptable/ },
    {status => 'proxy_authentication_required', expected => qr/407 Proxy Authentication Required/ },
    {status => '407', expected => qr/407 Proxy Authentication Required/ },
    {status => 'request_timeout', expected => qr/408 Request Timeout/ },
    {status => '408', expected => qr/408 Request Timeout/ },
    {status => 'conflict', expected => qr/409 Conflict/ },
    {status => '409', expected => qr/409 Conflict/ },
    {status => 'gone', expected => qr/410 Gone/ },
    {status => '410', expected => qr/410 Gone/ },
    {status => 'length_required', expected => qr/411 Length Required/ },
    {status => '411', expected => qr/411 Length Required/ },
    {status => 'precondition_failed', expected => qr/412 Precondition Failed/ },
    {status => '412', expected => qr/412 Precondition Failed/ },
    {status => 'request_entity_too_large', expected => qr/413 Request Entity Too Large/ },
    {status => '413', expected => qr/413 Request Entity Too Large/ },
    {status => 'request_uri_too_long', expected => qr/414 Request-URI Too Long/ },
    {status => '414', expected => qr/414 Request-URI Too Long/ },
    {status => 'unsupported_media_type', expected => qr/415 Unsupported Media Type/ },
    {status => '415', expected => qr/415 Unsupported Media Type/ },
    {status => 'requested_range_not_satisfiable', expected => qr/416 Requested Range Not Satisfiable/ },
    {status => '416', expected => qr/416 Requested Range Not Satisfiable/ },
    {status => 'expectation_failed', expected => qr/417 Expectation Failed/ },
    {status => '417', expected => qr/417 Expectation Failed/ },

    {status => 'internal_server_error', expected => qr/500 Internal Server Error/ },
    {status => '500', expected => qr/500 Internal Server Error/ },
    {status => 'not_implemented', expected => qr/501 Not Implemented/ },
    {status => '501', expected => qr/501 Not Implemented/ },
    {status => 'bad_gateway', expected => qr/502 Bad Gateway/ },
    {status => '502', expected => qr/502 Bad Gateway/ },
    {status => 'service_unavailable', expected => qr/503 Service Unavailable/ },
    {status => '503', expected => qr/503 Service Unavailable/ },
    {status => 'gateway_timeout', expected => qr/504 Gateway Timeout/ },
    {status => '504', expected => qr/504 Gateway Timeout/ },
    {status => 'http_version_not_supported', expected => qr/505 HTTP Version Not Supported/ },
    {status => '505', expected => qr/505 HTTP Version Not Supported/ },

    # additional aliases
    {status => 'error', expected => qr/500 Internal Server Error/ },
);

plan tests => scalar(@tests);

foreach my $test (@tests) {
    like(status($test->{status}), 
        $test->{expected}, 
        "status header looks good for ".$test->{status});
}

