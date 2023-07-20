use Test::Most;


use aliased 'OpenTracing::Implementation::DataDog::Tracer';



subtest 'Carrier as an hash reference' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_resource_name => 'rsrc_name',
            default_service_name  => 'srvc_name',
            default_service_type  => 'web',
        );
    } "Can create a Tracer, with some defaults"
    
    or return;
    
    my $context = $test_tracer->build_context( );
    
    my $original_carrier = {
#       something => 'here',
        something => 'there',
        someother => 'where',
    };
    
    my $injected_carrier;
    lives_ok {
        $injected_carrier = $test_tracer->inject_context_into_hash_reference(
            $original_carrier, $context,
        );
    } "... and could call `inject_context`"
    
    or return;
    
    cmp_deeply(
        $injected_carrier => {
#           something => 'here',
            something => 'there',
            someother => 'where',
            opentracing_context => {
                trace_id  => ignore(),
                span_id   => ignore(),
                resource  => 'rsrc_name',
                service   => 'srvc_name',
                type      => 'web',
            },
        },
        "... that has the expected key / value pairs"
    );
    
};


subtest 'Carrier as HTTP headers' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_resource_name => 'rsrc_name',
            default_service_name  => 'srvc_name',
            default_service_type  => 'web',
        );
    } "Can create a Tracer, with some defaults"
    
    or return;
    
    my $context = $test_tracer->build_context( );
    
    my $original_carrier = HTTP::Headers->new(
        first  => 'foo',
        second => 'bar',
    );
    
    my $injected_carrier;
    lives_ok {
        $injected_carrier = $test_tracer->inject_context_into_http_headers(
            $original_carrier, $context,
        );
    } "... and could call `inject_context`"
    
    or return;

    is $injected_carrier->header('first'), 'foo', 'first header preserved';
    is $injected_carrier->header('second'), 'bar', 'second header preserved';
    is $injected_carrier->header('x-datadog-trace-id'), $context->trace_id,
        'trace id injected';
    is $injected_carrier->header('x-datadog-parent-id'), $context->span_id,
        'span id injected';
};

done_testing();
