using Pkg
Pkg.activate(".")

using Accessors, LinearAlgebra, StatsBase, Plots, Random

include("src/GeneralizedJacksonSim.jl")
using .GeneralizedJacksonSim

include("test/scenarios.jl")  # some example network parameters
include("test/task3_test1.jl")
include("test/task3_test2.jl")

println("\n Task 2 returns plots of theoretical mean queue length:")
"""
    plot_total_ss_mean_queue_length(net::NetworkParameters)

Plots total steady state mean queue length as a function of ρ* for the given scenario.
"""
function plot_total_ss_mean_queue_length(net::NetworkParameters, scenario_number::Int64)
    ρ_star_values = 0.1:0.01:0.9
    total_ss_mean_queue_lengths = zeros(length(ρ_star_values))

    for (index, ρ_star) in enumerate(ρ_star_values)
        # adjust network parameters
        adjusted_scenario = set_scenario(net, ρ_star)
        ρ = compute_ρ(adjusted_scenario)

        total_ss_mean_queue_lengths[index] = sum(ρ ./ (1 .- ρ))
    end

    return plot(ρ_star_values,
                total_ss_mean_queue_lengths,
                xlabel="ρ",
                ylabel="Total Steady State Mean Queue Length",
                title="Scenario $scenario_number Theoretical")
end

p1 = plot_total_ss_mean_queue_length(scenario1, 1)
p2 = plot_total_ss_mean_queue_length(scenario2, 2)
p3 = plot_total_ss_mean_queue_length(scenario3, 3)
p4 = plot_total_ss_mean_queue_length(scenario4, 4)
        
display(plot(p1, p2, p3, p4, layout=(2, 2), legend=false, size=(800, 800)))


println("\n Task 3 was the generation of a simulation engine and can be found in the GeneralizedJacksonSim.jl file:")

scenarios = [scenario1, scenario2, scenario3, scenario4]

display(task3_test1(scenarios, verbose=false, multithreaded=false))
task3_test2(scenarios)



println("\n Task 4 plotted graphs for various service time values, and confidence bounds:")

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

return plot(p1,p2,p3,p4, layout=(4, 1), legend=true, size=(900, 900))

println("\n Task 5:")
# when running this in VSCode, use the "Julia: Execute active File in REPL" option or plots
# won't show up

# some of the tests take a considerable amount of time for scenario4, so it has been
# excluded here

# println("""An example network: here we have 3 queues in tandem, where jobs arrive to the
#         first queue, move onto the 2nd and 3rd queues respectively, and then leave the
#         system when they're done. Importantly, we require the network to be stable - that
#         is, the arrival rate to each node λ_i is less than the service rate μ_i. The load
#         for each node is defined as ρ_i = λ_i/μ_i, and we denote ρ* = max{ρ_i} as the
#         "bottleneck load". Thus, we require ρ* < 1 for the network to be stable.\n""")

# @show scenario1
# ρ = compute_ρ(scenario1)
# @show maximum(ρ)

# println("""\nA quantity we may be interested in is the total steady state mean queue length.
#         "Mean queue length" refers to the average length of the queue for each server over
#         the entire time period, and "total" refers to the sum of the mean queue lengths of
#         all servers. We can simulate running this scenario and obtain an estimate for the
#         total steady state mean queue length:\n""")

# @show sim_net(scenario1)

# println("""\nWe can confirm this estimate by solving the traffic equations to obtain the
#         theoretical mean queue length:\n""")

# @show sum(ρ ./ (1 .- ρ))

# println("\nVarying the bottleneck load ρ*:\n")

# for ρ_star in [0.1, 0.5, 0.9]
#     adjusted_scenario = set_scenario(scenario1, ρ_star)
#     local ρ = compute_ρ(adjusted_scenario)
#     println("ρ_star = $ρ_star:")
#     @show sim_net(adjusted_scenario)
#     @show sum(ρ ./ (1 .- ρ))
# end

# println("\nWe now introduce 2 more example scenarios:\n")

# @show scenario2
# @show scenario3

# println("""Intuitively, the simulation should more closely align with the theoretical
#         results the longer it runs. We can confirm this by observing the absolute relative
#         error for different scenarios and different values of `max_time`:\n""")

# display(task3_test1([scenario1, scenario2, scenario3]))

# println("""\nAnother quantity we may be interested in is the total (or mean) number of
#         arrivals to any given node. Once again, we can obtain estimates by running the
#         simulation, and verify these by solving the traffic equations to obtain λ:\n""")

# task3_test2([scenario1, scenario2, scenario3])

# println("""\nSomething else we can consider is the amount of time that customers spend in
#         the system (also known as sojourn time). After finishing service at a job, a
#         customer may either move to another job in the system, or exit the system (the
#         probability of doing so is determined by the P matrix). To simulate this, we can
#         keep track of every customer that arrives and record their arrival and departure
#         times. We can then calculate e.g. the mean or median time spent in the system:\n""")

# state = CustomerQueueNetworkState(scenario1)
# sim_net_customers(scenario1, state=state)
# sojourn_times = map((c) -> (c.departure - c.arrival), state.departed_customers)
# @show mean(sojourn_times)
# @show median(sojourn_times);
