"""
This file contains the NetworkParameters implementation and related functionality.
"""

"""
    NetworkParameters

# Fields
- `L::Int`: the dimension of the network (number of nodes)
- `α_vector::Vector{Float64}`: the external arrival rates α_i >= 0
- `μ_vector::Vector{Float64}`: the service rates μ_i > 0
- `P::Matrix{Float64}`: the L×L routing matrix P
- `cs::Float64`: squared coefficient of variation of the service processes, defaults to 1.0
"""
@with_kw struct NetworkParameters
    L::Int
    α_vector::Vector{Float64}
    μ_vector::Vector{Float64}
    P::Matrix{Float64}
    c_s::Float64 = 1.0
end

"""
    compute_ρ(net::NetworkParameters)

Computes the vector of ρ values for a given set of network parameters.
"""
function compute_ρ(net::NetworkParameters)
    λ = (I - net.P') \ net.α_vector  # solve traffic equations
    return λ ./ net.μ_vector  # vector of ρ values
end
