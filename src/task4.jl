using Pkg, Parameters, LinearAlgebra, Plots, Statistics, StatsBase, Random
Pkg.activate(".")

include("GeneralizedJacksonSim.jl")
using .GeneralizedJacksonSim
include("../test/scenarios.jl")

# include("network_parameters.jl")

c_s_value_values = [0.1,0.5,1.0,2.0,4.0]
scenarios = [scenario1, scenario2, scenario3, scenario4]

#generates the y-values for each c_s_value value for each scenario
function plot_mean_queue_length_c_s_values(net::NetworkParameters, scenario_number::Int64; max_time=10^3, warm_up_time=10)
    ρ_star_values = 0.01:0.01:0.9
    c_s_value_values = [0.1,0.5,1.0,2.0,4.0]
    plotting_data = Vector{Vector{Float64}}()
#forming data for each c_s_value value
    for (j,c_s_value) in enumerate(c_s_value_values)
        simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
        #forming data for each p*
        for (index, ρ_star) in enumerate(ρ_star_values)
            # adjust network parameters
            adjusted_net = set_scenario(net, ρ_star, c_s_value)
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)
            # get total steady state mean queue length
            simulated_total_mean_queue_lengths[index] = simulated
        end
        #pushes vector of mean queue lengths for each c_s_value value into plotting_data vector
        push!(plotting_data, simulated_total_mean_queue_lengths)
    end
    return plotting_data
end


#plots graphs for each scenario with varying c_s_value values displayed
function plotting_c_s_values(net::NetworkParameters, scenario_number::Int64)
    ρ_star_values = 0.01:0.01:0.9
    data = plot_mean_queue_length_c_s_values(net, scenario_number,max_time=10^3, warm_up_time=10)
    return plot(ρ_star_values,[data[1],data[2],data[3],data[4],data[5]], xlabel="ρ",
        ylabel="Total Mean Queue Length",
        title="Scenario $scenario_number Simulation with varying c_s values",
        labels=["0.1" "0.5" "1.0" "2.0" "4.0"])
end

#calculates and returns plot of confidence bounds for each scenario and c_s_value value
function confidence_bounds(net::NetworkParameters, scenario_number::Int64, c_s_value::Float64,max_time=10^3, warm_up_time=10)
    ρ_star_values = 0.01:0.01:0.9
    data = []
    mean_data=[]
    top_percentile = []
    bottom_percentile = []
        for (index, ρ_star) in enumerate(ρ_star_values)
            adjusted_net = set_scenario(net, ρ_star, c_s_value)
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
    title="Scenario $scenario_number with $c_s_value c_s", titlefontsize=10,
    
    labels=["mean" "95th percentile" "5th percentile"])
end

#plotting initial servcice time graphs
p1 = plotting_c_s_values(scenario1, 1)
p2 = plotting_c_s_values(scenario2, 2)
p3 = plotting_c_s_values(scenario3, 3)
p4 = plotting_c_s_values(scenario4, 4)

# return plot(p1,p2,p3,p4, layout=(4, 1), legend=true, size=(900, 900))

# plotting confidence bound graphs

plots = Vector()
for (index,scenario) in enumerate(scenarios)
  for c_s_value in c_s_value_values
    push!(plots, confidence_bounds(scenario, index, c_s_value))
  end
end
return plot(plots..., layout=(5, 4), legend=true, size=(1100, 1100))



        