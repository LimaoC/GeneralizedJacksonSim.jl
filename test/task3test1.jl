"""
This test compares the total mean queue lengths from the simulation, `sim_net()`, against
the theoretical total mean queue lengths - specifically, the absolute relative error for
varying ρ* values.
"""

function test_sim(net::NetworkParameters, scenario_number::Int64;
                  max_time::Int=10^5, warm_up_time::Int=10^3, verbose::Bool=false,
                  multithreaded::Bool=false)
    println("Simulating scenario $scenario_number...")
    ρ_star_values = 0.1:0.01:0.9
    simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
    absolute_relative_errors = zeros(length(ρ_star_values))

    if multithreaded
        Threads.@threads for index in eachindex(ρ_star_values)
            ρ_star = ρ_star_values[index]
            verbose && println("Running ρ* = $ρ_star in thread $(Threads.threadid())")

            # adjust network parameters to suit this ρ*
            adjusted_net = set_scenario(net, ρ_star)
            ρ = compute_ρ(adjusted_net)

            # calculate and simulate total mean queue lengths
            theoretical = sum(ρ ./ (1 .- ρ))
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)

            # save lengths to array
            simulated_total_mean_queue_lengths[index] = simulated
            absolute_relative_errors[index] = abs(theoretical - simulated) / theoretical
        end
    else
        # single-thread
        for (index, ρ_star) in enumerate(ρ_star_values)
            verbose && println("Running ρ* = $ρ_star")

            # adjust network parameters to suit this ρ*
            adjusted_net = set_scenario(net, ρ_star)
            ρ = compute_ρ(adjusted_net)

            # calculate and simulate total mean queue lengths
            theoretical = sum(ρ ./ (1 .- ρ))
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)

            # save lengths to array
            simulated_total_mean_queue_lengths[index] = simulated
            absolute_relative_errors[index] = abs(theoretical - simulated) / theoretical
        end
    end

    println("Scenario $scenario_number simulation done")

    return plot(
        ρ_star_values,
        simulated_total_mean_queue_lengths,
        xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number Simulation"
    ), plot(
        ρ_star_values,
        absolute_relative_errors,
        xlabel="ρ",
        ylabel="Abs. Rel. Error",
        title="Abs. Rel. Error of Scenario $scenario_number Simulation"
    )
end

function task3_test1(scenarios::Vector{NetworkParameters};
                     verbose::Bool=false, multithreaded=false)
    plots = Vector()
    for (scenario_number, scenario) in enumerate(scenarios)
        push!(plots, test_sim(scenario,
                              scenario_number,
                              verbose=verbose,
                              multithreaded=multithreaded)...)
    end
    plot(plots..., layout=(length(scenarios), 2), legend=false, size=(1000, 1000))
end
