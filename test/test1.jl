using Pkg
Pkg.activate(".")
include("../src/GeneralizedJacksonSim.jl")
include("../src/network_parameters.jl")
include("../src/state.jl")
include("../src/event.jl")

# Three queues in tandem
scenario1 = NetworkParameters(L=3, 
                              α_vector = [0.5, 0, 0],
                              μ_vector = ones(3),
                              P = [0 1.0 0;
                                   0 0 1.0;
                                   0 0 0])

# Three queues in tandem with option to return back to first queue
scenario2 = @set scenario1.P  = [0 1.0 0; #The @set macro is from Accessors.jl and allows to easily make a 
                                 0 0 1.0; # modified copied of an (immutable) struct
                                 0.3 0 0] 

# A ring of 5 queues
scenario3 = NetworkParameters(L=5, 
                              α_vector = ones(5),
                              μ_vector = collect(1:5),
                              P = [0  .8   0    0   0;
                                   0   0   .8   0   0;
                                   0   0   0    .8  0;
                                   0   0   0    0   .8;
                                   .8  0   0    0    0])

# A large arbitrary network
# Generate some random(arbitrary) matrix P
Random.seed!(0)
L = 100
P = rand(L,L)
P = P ./ sum(P, dims=2)  # normalize rows by the sum
P = P .* (0.2 .+ 0.7rand(L))  # multiply rows by factors in [0.2,0.9] 

scenario4 = NetworkParameters(L=L, 
                              α_vector = ones(L),
                              μ_vector = 0.5 .+ rand(L),
                              P = P);


ρ_star_values = 0.01:0.01:0.9

function simulation_test(net::NetworkParameters, scenario_number::Int64)
    absolute_relative_error = zeros(length(ρ_star_values))

    for (index,ρ_star) in enumerate(ρ_star_values)
        adjusted_net = set_scenario(net, ρ_star)  # adjust network parameters by this p*
        ρ = compute_ρ(adjusted_net)
        absolute_relative_error[index] = abs((sum(ρ ./ (1 .- ρ))) - sim_net(adjusted_net))
    end

    return plot(ρ_star_values,
                absolute_relative_error,
                xlabel="ρ",
                ylabel="Absolute Error",
                title="Scenario $scenario_number, Absolute Error of SImulation")
end

simulation_test(scenario1, 1)
simulation_test(scenario2, 2)
simulation_test(scenario3, 3)
simulation_test(scenario4, 4)

plot(p1, p2, p3, p4, layout=(2, 2), legend=false, size=(800, 800))
