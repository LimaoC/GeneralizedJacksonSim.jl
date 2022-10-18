using Pkg, Parameters, LinearAlgebra, Plots, Statistics, StatsBase
Pkg.activate(".")

include("../simulation_script.jl")

include("../test/scenarios.jl")

service_time_values = [0.1,0.5,1.0,2.0,4.0]
scenarios = [scenario1, scenario2, scenario3, scenario4]

#generates the y-values for each service time for each scenario
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
        #pushes vector of mean queue lengths for each service time into plotting_data vector
        push!(plotting_data, simulated_total_mean_queue_lengths)
    end
    return plotting_data
end


#plots graphs for each scenario with varying service times displayed
function plotting_service_times(net::NetworkParameters, scenario_number::Int64)
    ρ_star_values = 0.01:0.01:0.9
    data = plot_mean_queue_length_service_times(net, scenario_number,max_time=10^3, warm_up_time=10)
    return plot(ρ_star_values,[data[1],data[2],data[3],data[4],data[5]], xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number Simulation with varying service times",
        labels=["0.1" "0.5" "1.0" "2.0" "4.0"])
end

#calculates and returns plot of confidence bounds for each scenario and service time
function confidence_bounds(net::NetworkParameters, scenario_number::Int64, service_time::Float64,max_time=10^3, warm_up_time=10)
    ρ_star_values = 0.01:0.01:0.9
    data = []
    mean_data=[]
    top_percentile = []
    bottom_percentile = []
        for (index, ρ_star) in enumerate(ρ_star_values)
            adjusted_net = set_scenario(net, ρ_star, service_time)
            #generates simulated data for each p* 100 times at 100 varying seeds
            for seed in 1:100
                simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time,seed = seed)
                push!(data,simulated)
            end
        #pushes in the mean and upper and lower confidence bounds data
        push!(mean_data, mean(data))
        push!(top_percentile, percentile(data,95))
        push!(bottom_percentile, percentile(data,5))
        end
#plots confidence bounds graph
return plot(ρ_star_values,mean_data; ribbon = (bottom_percentile,top_percentile), xlabel="ρ",
    ylabel="Total Mean Queue Length",
    title="Scenario $scenario_number Simulation with $service_time service time, confidence bound",
    labels=["mean" "95th percentile" "5th percentile"])
end

#plotting initial servcice time graphs
p1 = plotting_service_times(scenario1, 1,)
p2 = plotting_service_times(scenario2, 2,)
p3 = plotting_service_times(scenario3, 3,)
p4 = plotting_service_times(scenario4, 4,)

return plot(p1,p2,p3,p4, layout=(4, 1), legend=true, size=(900, 900))

#plotting confidence bound graphs

plots = Vector()
for (index,scenario) in enumerate(scenarios)
  for service_time in service_time_values
    push!(plots, confidence_bounds(scenario, index, service_time))
  end
end
return plot(plots..., layout=(19, 1), legend=true, size=(1100, 1100))



        