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
- `c_s::Float64`: squared coefficient of variation of the service processes, defaults to 1.0
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

"""
Computes the maximal value by which we can scale the network's α_vector and be stable.
"""
function maximal_alpha_scaling(net::NetworkParameters)
    λ_base = (I - net.P') \ net.α_vector  # solve the traffic equations
    ρ_base = λ_base ./ net.μ_vector  # determine the load ρ  
    return minimum(1 ./ ρ_base)
end

"""
    set_scenario(net::NetworkParameters, ρ::Float64, c_s::Float64 = 1.0)

Adjusts the network parameters to the desired ρ⋆ and c_s.
"""
function set_scenario(net::NetworkParameters, ρ::Float64, c_s::Float64=1.0)
    (ρ ≤ 0 || ρ ≥ 1) && error("ρ is out of range")
    max_scaling = maximal_alpha_scaling(net)
    net = @set net.α_vector = net.α_vector * max_scaling * ρ
    net = @set net.c_s = c_s
    return net
end
