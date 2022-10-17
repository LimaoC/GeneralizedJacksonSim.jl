using Pkg, Parameters, LinearAlgebra, Plots, Statistics, StatsBase
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
    return plotting_data
end

function plotting_service_times(net::NetworkParameters, scenario_number::Int64)
    ρ_star_values = 0.01:0.01:0.9
    data = plot_mean_queue_length_service_times(net, scenario_number,max_time=10^3, warm_up_time=10)
    return plot(ρ_star_values,[data[1],data[2],data[3],data[4],data[5]], xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number Simulation with varying service times",
        labels=["0.1" "0.5" "1.0" "2.0" "4.0"])
end

function confidence_bounds(net::NetworkParameters, scenario_number::Int64, service_time::Float64,max_time=10^3, warm_up_time=10)
    ρ_star_values = 0.01:0.01:0.9
    data = []
    mean_data=[]
    top_percentile = []
    bottom_percentile = []
        for (index, ρ_star) in enumerate(ρ_star_values)
            adjusted_net = set_scenario(net, ρ_star, service_time)
            for seed in 1:100
                simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time,seed = seed)
                push!(data,simulated)
            end
        push!(mean_data, mean(data))
        push!(top_percentile, percentile(data,95))
        push!(bottom_percentile, percentile(data,5))
        end
return plot(ρ_star_values,mean_data; ribbon = (bottom_percentile,top_percentile), xlabel="ρ",
    ylabel="Total Mean Queue Length",
    title="Scenario $scenario_number Simulation with $service_time service time, confidence bound",
    labels=["mean" "95th percentile" "5th percentile"])
end

p1 = plotting_service_times(scenario1, 1,)
p2 = plotting_service_times(scenario2, 2,)
p3 = plotting_service_times(scenario3, 3,)
p4 = plotting_service_times(scenario4, 4,)

#note that running all of these confidence bound calculations at once takes a very long time and it is more beneficial to run each scenario's set individually
p5 = confidence_bounds(scenario1, 1, 0.1)
p6 = confidence_bounds(scenario1, 1, 0.5)
p7 = confidence_bounds(scenario1, 1, 1.0)
p8 = confidence_bounds(scenario1, 1, 2.0)
p9 = confidence_bounds(scenario1, 1, 4.0)
p10 = confidence_bounds(scenario2, 2, 0.1)
p12 = confidence_bounds(scenario2, 2, 0.5)
p13 = confidence_bounds(scenario2, 2, 1.0)
p14 = confidence_bounds(scenario2, 2, 2.0)
p15 = confidence_bounds(scenario2, 2, 4.0)
p16 = confidence_bounds(scenario3, 3, 0.1)
p17 = confidence_bounds(scenario3, 3, 0.5) 
p18 = confidence_bounds(scenario3, 3, 1.0)
p19 = confidence_bounds(scenario3, 3, 2.0)
p20 = confidence_bounds(scenario3, 3, 4.0)
p21 = confidence_bounds(scenario4, 4, 0.1)
p22 = confidence_bounds(scenario4, 4, 0.5)
p23 = confidence_bounds(scenario4, 4, 1.0)
p24 = confidence_bounds(scenario4, 4, 2.0)
p25 = confidence_bounds(scenario4, 4, 4.0)


return plot(p1,p2,p3,p4, layout=(4, 1), legend=true, size=(900, 900))

return plot(p5,p6,p7,p8,p9,p10,p12,p13,p14,p15,p16,p17,p18,p19,p20,p21,p22,p23,p24,p25, layout=(19, 1), legend=true, size=(1100, 1100))


        