"""
This file contains the State implementation and related functionality.
"""

"""A generic abstract State type."""
abstract type State end

"""
    QueueNetworkState

# Fields
- `queues::Vector{Int}`: vector of number of customers in each queue
- `num_queues::Int`: number of queues, equivalent to `length(queues)`
- `net::NetworkParameters`: the parameters of the network
"""
mutable struct QueueNetworkState <: State
    queues::Vector{Int}  # a vector which indicates the number of customers in each queue
    num_queues::Int  # this is the total of queues above (an INVARIANT in the system...)
    net::NetworkParameters  # the parameters of the network (queueing system)
end

"""
A wrapper around a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(rate::Float64, scv::Float64) = Gamma(1/scv, scv/rate)

"""
    next_arrival_time(s::State, q::Int)

Generates the next arrival time for the `q`th server. The duration of time between
external arrivals is exponentially distributed with mean 1 / s.net.α_vector[q].
"""
next_arrival_time(s::State, q::Int) = rand(Exponential(1/s.net.α_vector[q]))

"""
    next_service_time(s::State, q::Int)

Generates the next service time for the `q`th server. The service duration is gamma
distributed.
"""
next_service_time(s::State, q::Int) = rand(rate_scv_gamma(s.net.μ_vector[q], s.net.c_s))
