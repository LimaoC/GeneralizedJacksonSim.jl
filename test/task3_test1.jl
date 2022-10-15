"""
This test compares the total mean queue lengths from the simulation, `sim_net()`, against
the theoretical total mean queue lengths - specifically, the absolute relative error for
varying ρ* values.
"""

function test_sim(net::NetworkParameters, scenario_number::Int64;
                  max_times=[10^3, 10^4, 10^5],
                  warm_up_times=[10, 10^2, 10^3],
                  verbose::Bool=false,
                  multithreaded::Bool=false)
    @assert length(max_times) == length(warm_up_times)
    println("Simulating scenario $scenario_number...")
    ρ_star_values = 0.1:0.01:0.9
    simulated_total_mean_queue_lengths = Vector{Vector{Float64}}()
    # simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
    absolute_relative_errors = Vector{Vector{Float64}}()
    # absolute_relative_errors = zeros(length(ρ_star_values))

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
        simulated = Vector{Float64}()
        for i in eachindex(max_times)
            max_time, warm_up_time = max_times[i], warm_up_times[i]
            push!(simulated, sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time))
        end
        # simulated = sim_net.((adjusted_net,), max_time=max_times, warm_up_time=warm_up_times)

        # save lengths to array
        push!(simulated_total_mean_queue_lengths, simulated)
        # simulated_total_mean_queue_lengths[index] = simulated
        push!(absolute_relative_errors, abs.(theoretical .- simulated) ./ theoretical)
        # absolute_relative_errors[index] = abs(theoretical .- simulated) ./ theoretical
    end

    println("Scenario $scenario_number simulation done")

    # convert vector of vectors to matrix to be compatible with plot()
    simulated_total_mean_queue_lengths = [arr[k] for k in 1:3, arr in simulated_total_mean_queue_lengths]'
    absolute_relative_errors = [arr[k] for k in 1:3, arr in absolute_relative_errors]'

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
    plot(plots..., layout=(length(scenarios), 2), legend=true, size=(1000, 1000))
end
