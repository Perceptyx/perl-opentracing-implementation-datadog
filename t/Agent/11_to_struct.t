use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


use aliased 'OpenTracing::Implementation::DataDog::Agent';

use aliased 'OpenTracing::Implementation::DataDog::Span';
use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/is_Int/;

my $some_span_context = SpanContext->new(
    service_name    => 'srvc name',
    resource_name   => 'rsrc name',
    baggage_items   => { foo => 1, bar => 2 },
)->with_span_id(54365)->with_trace_id(87359);

my $this_span_context = $some_span_context->new_clone(
)->with_span_id(49603)->with_trace_id($some_span_context->trace_id);

my $test_span = Span->new(
    operation_name  => 'oprt name',
    child_of        => $some_span_context,
    context         => $this_span_context,
    start_time      => 52.750,
    tags            => { baz => 3, qux => 4 },
);

$test_span->finish( 83.500 );

my $struct = Agent->to_struct( $test_span );

cmp_deeply(
    $struct => {
        trace_id   => 87359,
        span_id    => 49603,
        type       => "custom",
        service    => "srvc name",
        resource   => "rsrc name",
        parent_id  => 54365,
        name       => "oprt name",
        start      => 52750000000, # nano seconds
        duration   => 30750000000, # nano seconds
        meta       => {
            bar        => 2,
            baz        => 3,
            foo        => 1,
            qux        => 4,
        },
    },
    "Extracted the right structure, including DataDog specifics"
);

done_testing();
