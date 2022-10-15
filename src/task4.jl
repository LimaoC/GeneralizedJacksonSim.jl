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
    service_time_values = [0.1,0.5,1.0,2.0,4.0]
    plotting_data = Vector{Vector{Float64}}()
#forming data for each service time
    for (j,service_time) in enumerate(service_time_values)
        simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
        #forming data for each p*
        for (index, ρ_star) in enumerate(ρ_star_values)
            # adjust network parameters
            adjusted_net = set_scenario(net, ρ_star, service_time)
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)
            # get total steady state mean queue length
            simulated_total_mean_queue_lengths[index] = simulated
        end

        push!(plotting_data, simulated_total_mean_queue_lengths)
    end
    
    return plot(ρ_star_values,[plotting_data[1],plotting_data[2],plotting_data[3],plotting_data[4],plotting_data[5]], xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number Simulation with varying service times",
        labels=["0.1" "0.5" "1.0" "2.0" "4.0"])


    end



p1 = plot_mean_queue_length_service_times(scenario1, 1)
p2 = plot_mean_queue_length_service_times(scenario2, 2)
p3 = plot_mean_queue_length_service_times(scenario3, 3)
p4 = plot_mean_queue_length_service_times(scenario4, 4)
        
plot(p1, p2, p3, p4, layout=(2, 2), legend=true, size=(800, 800))