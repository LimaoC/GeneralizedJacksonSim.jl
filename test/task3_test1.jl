"""
This test compares the total mean queue lengths from the simulation, `sim_net()`, against
the theoretical total mean queue lengths - specifically, the absolute relative error for
varying ρ* values.
"""

"""
    test_sim(net::NetworkParameters, scenario_number::Int64; max_times::Vector{Int},
             warm_up_times::Vector{Int}, verbose::Bool, multithreaded::Bool)

Plots the simulated total mean queue length against the theoretical total mean queue
length, as well as the absolute relative error between the two.
"""
function test_sim(net::NetworkParameters, scenario_number::Int64;
                  max_times::Vector{Int}=[10^3, 10^4, 10^5],
                  warm_up_times::Vector{Int}=[10, 10^2, 10^3],
                  verbose::Bool=false,
                  multithreaded::Bool=false)
    @assert length(max_times) == length(warm_up_times)
    println("Simulating scenario $scenario_number...")    

    # each element stores a vector of simulations for each max_time & warm_up_time pair
    ρ_star_values = 0.1:0.01:0.9
    sim_total_mean_lengths = Vector{Vector{Float64}}(undef, length(ρ_star_values))
    abs_rel_errors = Vector{Vector{Float64}}(undef, length(ρ_star_values))

    # we want to broadcast sim_net() for each max_time & warm_up_time pair, but keyword
    # arguments can't be broadcasted, so a workaround is to wrap sim_net() with a function
    # that doesn't have keyword arguments
    # https://discourse.julialang.org/t/what-is-interaction-between-f-broadcasting-and-keyword-args/3648/6
    function wrapped_sim_net(net, max_time, warm_up_time)
        sim_net(net, max_time=max_time, warm_up_time=warm_up_time)
    end

    # calculate theoretical and simulated total mean queue lengths
    Threads.@threads for index in eachindex(ρ_star_values)
        ρ_star = ρ_star_values[index]
        verbose && (multithreaded ?
            println("Running ρ* = $ρ_star in thread $(Threads.threadid())") :
            println("Running ρ* = $ρ_star"))

        # adjust network parameters to suit this ρ*
        adjusted_net = set_scenario(net, ρ_star)
        ρ = compute_ρ(adjusted_net)

        # calculate and simulate total mean queue lengths
        theoretical = sum(ρ ./ (1 .- ρ))
        simulated = wrapped_sim_net.((adjusted_net,), max_times, warm_up_times)

        # save lengths to array
        sim_total_mean_lengths[index] = simulated
        abs_rel_errors[index] = abs.(theoretical .- simulated) ./ theoretical
    end

    println("Scenario $scenario_number simulation done")

    # convert vector of vectors to matrix to be compatible with plot()
    dim = length(max_times)
    sim_total_mean_lengths = [arr[k] for k in 1:dim, arr in sim_total_mean_lengths]'
    abs_rel_errors = [arr[k] for k in 1:dim, arr in abs_rel_errors]'

    return plot(
        ρ_star_values,
        sim_total_mean_lengths,
        xlabel="ρ",
        ylabel="Total Mean Queue Length",
        labels=hcat("max_time: " .* string.(max_times)...),
        title="Scenario $scenario_number Simulation"
    ), plot(
        ρ_star_values,
        abs_rel_errors,
        xlabel="ρ",
        ylabel="Abs. Rel. Error",
        labels=hcat("max_time: " .* string.(max_times)...),
        title="Abs. Rel. Error of Scenario $scenario_number Simulation"
    )
end

"""
    task3_test1(scenarios::Vector{NetworkParameters}, verbose::Bool=false,
                multithreaded=false)

Runs test_sim() for each of the given scenarios.
"""
function task3_test1(scenarios::Vector{NetworkParameters};
                     verbose::Bool=false, multithreaded=false)
    plots = Vector()
    for (scenario_number, scenario) in enumerate(scenarios)
        push!(plots, test_sim(scenario,
                              scenario_number,
                              verbose=verbose,
                              multithreaded=multithreaded)...)
    end
    plot(plots..., layout=(length(scenarios), 2), legend=true, size=(1000, 1000))
end
