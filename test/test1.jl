"""
This test compares the total mean queue lengths from the simulation, `sim_net()`, against
the theoretical total mean queue lengths - specifically, the absolute relative error for
varying ρ* values.
"""

# Three queues in tandem
scenario1 = NetworkParameters(
    L=3,
    α_vector=[0.5, 0, 0],
    μ_vector=ones(3),
    P=[0 1.0 0
        0 0 1.0
        0 0 0])

# Three queues in tandem with option to return back to first queue
scenario2 = @set scenario1.P = [  # The @set macro is from Accessors.jl and allows to
    0 1.0 0                       # easily make a modified copy of an (immutable) struct
    0 0 1.0
    0.3 0 0]

# A ring of 5 queues
scenario3 = NetworkParameters(
    L=5,
    α_vector=ones(5),
    μ_vector=collect(1:5),
    P=[0 0.8 0 0 0
        0 0 0.8 0 0
        0 0 0 0.8 0
        0 0 0 0 0.8
        0.8 0 0 0 0])

# A large arbitrary network - generate some random (arbitrary) matrix P
Random.seed!(0)
L = 100
P = rand(L, L)
P = P ./ sum(P, dims=2)  # normalize rows by the sum
P = P .* (0.2 .+ 0.7rand(L))  # multiply rows by factors in [0.2,0.9] 

scenario4 = NetworkParameters(
    L=L,
    α_vector=ones(L),
    μ_vector=0.5 .+ rand(L),
    P=P);

function sim_test(net::NetworkParameters, scenario_number::Int64, max_time::Int = 10^3, warm_up_time::Int = 10)
    ρ_star_values = 0.01:0.01:0.9
    simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
    
    for (index, ρ_star) in enumerate(ρ_star_values)
        adjusted_net = set_scenario(net, ρ_star)  # adjust network parameters by this p*
        simulated_total_mean_queue_lengths[index] = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time) 
    end
    return plot(ρ_star_values,
    simulated_total_mean_queue_lengths,
        xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number, Simulation")
end


function sim_test_absolute_relative_error(net::NetworkParameters, scenario_number::Int64,
                                          max_time::Int = 10^3, warm_up_time::Int = 10)
    ρ_star_values = 0.01:0.01:0.9
    absolute_relative_error = zeros(length(ρ_star_values))

    for (index, ρ_star) in enumerate(ρ_star_values)
        adjusted_net = set_scenario(net, ρ_star)  # adjust network parameters by this p*
        ρ = compute_ρ(adjusted_net)

        # calculate and simulate total mean queue lengths
        theoretical = sum(ρ ./ (1 .- p))
        simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)
        absolute_relative_error[index] = abs(theoretical - simulated ) / theoretical
    end

    return plot(ρ_star_values,
        absolute_relative_error,
        xlabel="ρ",
        ylabel="Absolute Error",
        title="Absolute Error of Scenario $scenario_number, Simulation")
end

p1 = sim_test(scenario1, 1)
p2 = sim_test(scenario2, 2)
p3 = sim_test(scenario3, 3)
p4 = sim_test(scenario4, 4)

plot(p1, p2, p3, p4, layout=(2, 2), legend=false, size=(800, 800))


# hold off from running this for a sec, I'm still refactoring this function
# p5 = sim_test_absolute_relative_error(scenario1, 1)
# p6 = sim_test_absolute_relative_error(scenario2, 2)
# p7 = sim_test_absolute_relative_error(scenario3, 3)
# p8 = sim_test_absolute_relative_error(scenario4, 4)

# plot(p5, p6, p7, p8, layout=(2, 2), legend=false, size=(800, 800))