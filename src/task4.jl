using Pkg, Parameters, LinearAlgebra, Plots
Pkg.activate(".")

# include("network_parameters.jl")
# include("state.jl")
# include("event.jl")
# include("GeneralizedJacksonSim.jl")

include("../simulation_script.jl")

include("../test/scenarios.jl")



function plot_mean_queue_length_service_times(net::NetworkParameters, scenario_number::Int64; max_time=10^3, warm_up_time=10)
    ρ_star_values = 0.01:0.01:0.9
    simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
    service_time_values = [0.1,0.5,1.0,2.0,4.0]
    plots = Vector()
#forming data for each service time
    for (j,service_time) in enumerate(service_time_values)
        #forming data for each p*
        for (index, ρ_star) in enumerate(ρ_star_values)
            # adjust network parameters
            adjusted_net = set_scenario(net, ρ_star, service_time)
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)
            # get total steady state mean queue length
            simulated_total_mean_queue_lengths[index] = simulated
        end
        #generating plot for each service time
        push!(plots, plot(
            ρ_star_values,
            simulated_total_mean_queue_lengths,
            xlabel="ρ",
            ylabel="Total Mean Queue Length",
            title="Scenario $scenario_number Simulation"))
    end
    # f = plot(plots[1])
    # g = plot!(f,plots[2])

    # return g
    # return plot!(plots[1],plots[2],plots[3],plots[4],plots[5],legend=true, size=(1000, 1000))
    # return plot(plots..., legend=true, size=(1000, 1000)) ##needs to combine all plots for service times from above onto one figure
    
    end

    # plots = Vector()
    # for (scenario_number, scenario) in enumerate(scenarios)
    #     push!(plots, test_sim(scenario,
    #                           scenario_number,
    #                           verbose=verbose,
    #                           multithreaded=multithreaded)...)
    # end
    # plot(plots..., layout=(length(scenarios), 2), legend=true, size=(1000, 1000))





p1 = plot_mean_queue_length_service_times(scenario1, 1)
# p2 = plot_mean_queue_length_service_times(scenario2, 2)
# p3 = plot_mean_queue_length_service_times(scenario3, 3)
# p4 = plot_mean_queue_length_service_times(scenario4, 4)
        
# plot(p1, p2, p3, p4, layout=(2, 2), legend=false, size=(800, 800))