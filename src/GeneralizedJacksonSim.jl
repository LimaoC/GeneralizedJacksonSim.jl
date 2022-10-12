"""
A discrete event simulation engine for Open Generalized Jackson Networks.
"""
module GeneralizedJacksonSim

using Parameters
using Accessors
using LinearAlgebra
using Random

include("network_parameters.jl")
include("state.jl")
include("event.jl")

export NetworkParameters, compute_ρ

"""
Runs a discrete event simulation of an Open Generalized Jackson Network `net`.

The simulation runs from time `0` to `max_time`.

Statistics about the total mean queue lengths are recorded from `warm_up_time` onwards
and the estimated value is returned.

This simulation does NOT keep individual customers' state, it only keeps the state which is
the number of items in each of the nodes.
"""
function sim_net(net::NetworkParameters; max_time = 10^6, warm_up_time = 10^4,
                 seed::Int64 = 42)::Float64
    Random.seed!(seed)

    # create priority queue and add standard events
    priority_queue = BinaryMinHeap{TimedEvent}()
    push!(priority_queue, TimedEvent(ArrivalEvent(), 0.0))
    push!(priority_queue, TimedEvent(EndSimEvent(), max_time))
end

end
