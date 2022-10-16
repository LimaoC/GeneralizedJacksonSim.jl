"""
A discrete event simulation engine for Open Generalized Jackson Networks.
"""
module GeneralizedJacksonSim

import Base: isless
using Accessors, DataStructures, Distributions, StatsBase, Parameters, LinearAlgebra,
    Random, Plots

include("network_parameters.jl")
include("state.jl")
include("event.jl")

export NetworkParameters, compute_ρ, maximal_alpha_scaling, set_scenario, sim_net

"""
Runs a discrete event simulation of an Open Generalized Jackson Network `net`.

The simulation runs from time `0` to `max_time`.

Statistics about the total mean queue lengths are recorded from `warm_up_time` onwards
and the estimated value is returned.

This simulation does NOT keep individual customers' state, it only keeps the state which is
the number of items in each of the nodes.
"""
function sim_net(net::NetworkParameters;
                 max_time=10^6, warm_up_time=10^4, seed::Int64=42)::Float64
    Random.seed!(seed)

    # initialise state and time
    state = QueueNetworkState(zeros(Int64, net.L), zeros(Int64, net.L), net.L, net)
    time = 0.0

    # create priority queue and add standard events
    priority_queue = BinaryMinHeap{TimedEvent}()
    for q in 1:net.L
        push!(priority_queue,
            TimedEvent(ExternalArrivalEvent(q), next_arrival_time(state, q)))
    end
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))

    # set up queues integral for computing total mean queue length
    queues_integral = zeros(net.L)
    last_time = 0.0

    """
    Records the queue integral of the given state at the given point in time.
    """
    function record_integral(time::Float64, state::State)
        (time >= warm_up_time) && (queues_integral += state.queues * (time - last_time))
        last_time = time
    end

    record_integral(time, state)

    # simulation loop
    while true
        # process the next upcoming event
        timed_event = pop!(priority_queue)
        time = timed_event.time
        new_timed_events = process_event(time, state, timed_event.event)

        isa(timed_event.event, EndSimEvent) && break

        # add new spawned events to queue
        for nte in new_timed_events
            push!(priority_queue, nte)
        end

        # record mean queue length
        record_integral(time, state)
    end

    println("$(state.arrivals)")
    println("simulated: $(state.arrivals ./ max_time)")
    println("theoretical: $((I - net.P') \ net.α_vector)")
    return sum(queues_integral / max_time)
end

end  # end of module
