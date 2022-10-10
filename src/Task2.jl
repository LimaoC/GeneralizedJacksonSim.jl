#most of this code is copy and pasted, my code/attempts/ messign around/ideas starts around line 87

using Parameters  
using Accessors 
using LinearAlgebra
using Random 
using Plots

@with_kw struct NetworkParameters #The @with_kw macro comes from the Parameters.jl package and makes nice constructors
    L::Int
    α_vector::Vector{Float64} #This vector is a vector of α_i which can then be scaled
    μ_vector::Vector{Float64} #This is the vector of service rates considered fixed
    P::Matrix{Float64} #routing matrix
    c_s::Float64 = 1.0 #The squared coefficient of variation of the service times with a default value of 1.0
end

############################
# Three queues in tandem
scenario1 = NetworkParameters(  L=3, 
                                α_vector = [0.5, 0, 0],
                                μ_vector = ones(3),
                                P = [0 1.0 0;
                                     0 0 1.0;
                                     0 0 0])

############################
# Three queues in tandem with option to return back to first queue
scenario2 = @set scenario1.P  = [0 1.0 0; #The @set macro is from Accessors.jl and allows to easily make a 
                                 0 0 1.0; # modified copied of an (immutable) struct
                                 0.3 0 0] 

############################
# A ring of 5 queues
scenario3 = NetworkParameters(  L=5, 
                                α_vector = ones(5),
                                μ_vector = collect(1:5),
                                P = [0  .8   0    0   0;
                                     0   0   .8   0   0;
                                     0   0   0    .8  0;
                                     0   0   0    0   .8;
                                     .8  0   0    0    0])

############################
# A large arbitrary network

#Generate some random(arbitrary) matrix P
Random.seed!(0)
L = 100
P = rand(L,L)
P = P ./ sum(P, dims=2) #normalize rows by the sum
P = P .* (0.2 .+ 0.7rand(L)) # multiply rows by factors in [0.2,0.9] 

scenario4 = NetworkParameters(  L=L, 
                                α_vector = ones(L),
                                μ_vector = 0.5 .+ rand(L),
                                P = P);

"""
Compute the maximal value by which we can scale the α_vector and be stable.
"""
function maximal_alpha_scaling(net::NetworkParameters)
    λ_base = (I - net.P') \ net.α_vector #Solve the traffic equations
    ρ_base = λ_base ./ net.μ_vector #Determine the load ρ  
    return minimum(1 ./ ρ_base) #Return the maximal value by 
end

max_scalings = round.(maximal_alpha_scaling.([scenario1, scenario2, scenario3, scenario4]),digits=3)
println("The maximal scalings for scenarios 1 to 4 are: $max_scalings")

"""
Use this function to adjust the network parameters to the desired ρ⋆ and c_s
"""
function set_scenario(net::NetworkParameters, ρ::Float64, c_s::Float64 = 1.0)
    (ρ ≤ 0 || ρ ≥ 1) && error("ρ is out of range")  
    max_scaling = maximal_alpha_scaling(net)
    net = @set net.α_vector = net.α_vector*max_scaling*ρ
    net = @set net.c_s = c_s
    return net
end;

function compute_ro(net::NetworkParameters)
    λ = (I- net.P') \ net.α_vector #solve traffic equations
    return λ./ net.μ_vector #this is the vector of ro values
end


## i believe the below code would have to be run for each scenario 1-4, and plots 
x_coords=[] #i don't think i initialised these correctly
y_coords=[]
for x in 0.1:0.1:0.9 #not sure what intervals/ro values this needs to run for yet
    adjusted_net = set_scenario(scenario3, x)
    ro = compute_ro(adjusted_net)
    mean_qs = ro ./ (1 .- ro)
    total_mean_ro = sum(mean_qs) #### need to collect this point to plot once the for loop has run
    push!(x_coords,x)
    push!(y_coords,total_mean_ro)
end

p1 = plot(x_coords,y_coords)
plot(p1)






# # @show P

# #We can check by solving the traffic equations
# λ = (I - adjusted_net.P') \ adjusted_net.α_vector #Solve the traffic equations
# ρ = λ ./ adjusted_net.μ_vector #This is the vector of ρ values
# ρ_star= maximum(ρ) #\star + [TAB]
# @show ρ_star;