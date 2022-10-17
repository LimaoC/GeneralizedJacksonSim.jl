"""
This file contains the State implementation and related functionality.
"""

"""A generic abstract State type."""
abstract type State end

"""
    QueueNetworkState

# Fields
- `queues::Vector{Int64}`: vector of number of customers in each queue
- `arrivals::Vector{Int64}`: vector of number of arrivals to each queue
- `num_queues::Int64`: number of queues, equivalent to `length(queues)`
- `net::NetworkParameters`: the parameters of the network
"""
mutable struct QueueNetworkState <: State
    queues::Vector{Int64}
    arrivals::Vector{Int64}
    num_queues::Int64
    net::NetworkParameters

    # Inner constructor for a given scenario's parameters
    function QueueNetworkState(net::NetworkParameters)
        new(zeros(Int64, net.L), zeros(Int64, net.L), net.L, net)
    end
end

"""
    CustomerQueueNetworkState

# Fields
- `queues::Vector{Queue{Customer}}`: vector of queues which store Customers
- `arrivals::Vector{Int64}`: vector of number of arrivals to each queue
- `num_queues::Int64`: number of queues, equivalent to `length(queues)`
- `net::NetworkParameters`: the parameters of the network
"""
mutable struct CustomerQueueNetworkState <: State
    queues::Vector{Queue{Customer}}
    departed_customers::Vector{Customer}
    arrivals::Vector{Int64}
    num_queues::Int64
    net::NetworkParameters

    # Inner constructor for a given scenario's parameters
    function CustomerQueueNetworkState(net::NetworkParameters)
        queues = Vector{Queue{Customer}}()
        for _ in 1:net.L
            push!(queues, Queue{Customer}())
        end
        new(queues, Vector{Customer}(), zeros(Int64, net.L), net.L, net)
    end
end

"""
A wrapper around a Gamma distribution with desired rate (inverse of shape) and SCV.
"""
rate_scv_gamma(rate::Float64, scv::Float64) = Gamma(1/scv, scv/rate)

"""
    next_arrival_time(s::State, q::Int64)

Generates the next external arrival time for the `q`th server. The duration of time between
external arrivals is exponentially distributed with mean 1 / s.net.α_vector[q].
"""
next_arrival_time(s::State, q::Int64) = rand(Exponential(1/s.net.α_vector[q]))

"""
    next_service_time(s::State, q::Int64)

Generates the next service time for the `q`th server. The service duration is gamma
distributed.
"""
next_service_time(s::State, q::Int64) = rand(rate_scv_gamma(s.net.μ_vector[q], s.net.c_s))
