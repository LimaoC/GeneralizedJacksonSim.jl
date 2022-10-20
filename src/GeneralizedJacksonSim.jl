"""
A discrete event simulation engine for Open Generalized Jackson Networks.
"""
module GeneralizedJacksonSim

import Base: isless
using Accessors, DataStructures, Distributions, LinearAlgebra, Parameters, StatsBase,
    Random, Plots

include("network_parameters.jl")
include("customer.jl")
include("state.jl")
include("event.jl")

export NetworkParameters, QueueNetworkState, CustomerQueueNetworkState, sim_net,
    sim_net_customers, compute_ρ, maximal_alpha_scaling, set_scenario

"""
Runs a discrete event simulation of an Open Generalized Jackson Network `net`.

The simulation runs from time `0` to `max_time`.

Statistics about the total mean queue lengths are recorded from `warm_up_time` onwards
and the estimated value is returned.

This simulation does NOT keep individual customers' state, it only keeps the state which is
the number of items in each of the nodes.
"""
function sim_net(net::NetworkParameters;
                 state::State=QueueNetworkState(net), max_time::Int64=10^6,
                 warm_up_time::Int64=10^4, seed::Int64=42)::Float64
    Random.seed!(seed)

    # create priority queue and add standard events
    priority_queue = BinaryMinHeap{TimedEvent}()
    for q in 1:net.L
        if net.α_vector[q] > 0
            push!(priority_queue,
                TimedEvent(ExternalArrivalEvent(q), next_arrival_time(state, q)))
        end
    end
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))

    # set up queues integral for computing total mean queue length
    queues_integral = 0
    queue_total = 0
    time = 0.0
    last_time = 0.0

    """
    Records the queue integral of the given state at the given point in time.
    """
    function record_integral(time::Float64)
        if time >= warm_up_time
            queues_integral += sum(queue_total * (time - last_time))
        end
        last_time = time
    end

    record_integral(time)

    # simulation loop
    while true
        queue_total = sum(state.queues)
        # process the next upcoming event
        timed_event = pop!(priority_queue)
        time = timed_event.time
        new_timed_events = process_event(time, state, timed_event.event)

        # record queue length
        record_integral(time)

        # end sim if we've reached the EndOfSim event
        isa(timed_event.event, EndSimEvent) && break

        # add new spawned events to queue
        for nte in new_timed_events
            push!(priority_queue, nte)
        end
    end

    return queues_integral / (max_time - warm_up_time)
end

"""
Runs a discrete event simulation of an Open Generalized Jackson Network `net`.

The simulation runs from time `0` to `max_time`.

Statistics about the total mean queue lengths are recorded from `warm_up_time` onwards
and the estimated value is returned.

This simulation keeps track of individual customer states - specifically, the time at which
they enter the system and the time at which they exit.
"""
function sim_net_customers(net::NetworkParameters;
                           state::State=CustomerQueueNetworkState(net),
                           max_time::Int64=10^6, warm_up_time::Int64=10^4,
                           seed::Int64=42)::Float64
    Random.seed!(seed)

    # create priority queue and add standard events
    priority_queue = BinaryMinHeap{TimedEvent}()
    for q in 1:net.L
        if net.α_vector[q] > 0
            push!(priority_queue,
                TimedEvent(CustomerExternalArrivalEvent(q), next_arrival_time(state, q)))
        end
    end
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))

    # set up queues integral for computing total mean queue length
    queues_integral = 0
    queue_total = 0
    time = 0.0
    last_time = 0.0

    """
    Records the queue integral of the given state at the given point in time.
    """
    function record_integral(time::Float64)
        if time >= warm_up_time
            queues_integral += sum(queue_total * (time - last_time))
            # queues_integral += sum(map((queue) -> length(queue), state.queues) *
            #     (time - last_time))
        end
        last_time = time
    end

    record_integral(time)

    # simulation loop
    while true
        queue_total = sum(map((queue) -> length(queue), state.queues))
        # process the next upcoming event
        timed_event = pop!(priority_queue)
        time = timed_event.time
        new_timed_events = process_event(time, state, timed_event.event)

        # record mean queue length
        record_integral(time)

        # end sim if we've reached the EndOfSim event
        isa(timed_event.event, EndSimEvent) && break

        # add new spawned events to queue
        for nte in new_timed_events
            push!(priority_queue, nte)
        end
    end

    return queues_integral / (max_time - warm_up_time)
end

end  # end of module
