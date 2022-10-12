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
