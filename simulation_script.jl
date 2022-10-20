using Pkg
Pkg.activate(".")

using Accessors, LinearAlgebra, StatsBase, Plots, Random

include("src/GeneralizedJacksonSim.jl")
using .GeneralizedJacksonSim

include("test/scenarios.jl")  # some example network parameters
include("test/task3_test1.jl")
include("test/task3_test2.jl")

scenarios = [scenario1, scenario2, scenario3, scenario4]

println("""
        TASK 2
        To calculate the theoretical total steady state mean queue length of a network, we
        can compute ρ_i / (1 - ρ_i). Intuitively, as ρ* (the bottleneck load) gets larger,
        the total mean queue length should also get larger. We can confirm this by plotting
        the theoretical total mean queue length for varying ρ* (all < 1 to ensure the
        network is stable):
        """)

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
                xlabel="ρ*",
                ylabel="Total Steady State Mean Queue Length",
                title="Scenario $scenario_number Theoretical")
end

plots = Vector()
for (index, scenario) in enumerate(scenarios)
    push!(plots, plot_total_ss_mean_queue_length(scenario1, index))
end
display(plot(plots..., layout=(2, 2), legend=false, size=(800, 800)))

println("""
        TASK 3
        The simulation engine code can be found in `src/`, and the main simulation function,
        `sim_net()`, can be found in `src/GeneralizedJacksonSim.jl`.
        """)

println("""
        TASK 3: Test 1
        By recording the queue lengths of all the queues at various points throughout the
        simulation, we can obtain an estimated total mean queue length from the simulation.
        To verify this estimate, we can compare it against the theoretical total mean queue
        lengths (same computation for the theoretical values as in task 2).
        """)

# display(task3_test1(scenarios, verbose=true, multithreaded=false))

println("""
        TASK 3: Test 2
        We can also estimate the mean number of arrivals to each node (both from inside and
        outside the system) by simulation, and once again compare this to the theoretical
        values (λ_i):
        """)

task3_test2(scenarios)

println("""
        TASK 4
        We can also vary the c_s value of the network, which is the squared coefficient of
        variation of the service processes. We expect that as c_s increases, the curve
        increases as well:
        """)

service_time_values = [0.1, 0.5, 1.0, 2.0, 4.0]

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
return plot(plots..., layout=(10, 2), legend=true, size=(1100, 1100))

return plot(p1,p2,p3,p4, layout=(4, 1), legend=true, size=(900, 900))

println("""
        TASK 5
        We can measure the amount of time that customers spend in the system (also known as
        sojourn time). After finishing service at a job, a customer may either move to
        another job in the system, or exit the system - the probability of doing so is
        determined by the P matrix. To simulate this, we can keep track of every customer
        that arrives and record their arrival and departure times. We can then calculate
        e.g. the Q1, median (Q2), and Q3 time spent in the system:
        """)

function estimate_sojourn_time(scenarios::Vector{NetworkParameters}; max_time::Int64=10^6,
                               warm_up_time::Int64=10^4, ρ_star::Float64=0.8,
                               c_s_values::Vector{Float64}=[0.5, 1.0, 2.0])
    for (index, scenario) in enumerate(scenarios)
        println("Simulating scenario $index...")
        scenario = set_scenario(scenario, ρ_star)
        for c_s in c_s_values
            println("    c_s = $c_s:")
            scenario = @set scenario.c_s = c_s
            state = CustomerQueueNetworkState(scenario)
            sim_net_customers(scenario, state=state, max_time=max_time,
                              warm_up_time=warm_up_time)

            sojourn_times = map((c) -> (c.departure - c.arrival), state.departed_customers)
            quartiles = nquantile(sojourn_times, 4)
            println("        Estimated Q1: $(quartiles[2])")
            println("        Estimated Q2: $(quartiles[3])")
            println("        Estimated Q3: $(quartiles[4])")
        end
    end
end

estimate_sojourn_time(scenarios, max_time=10^5, warm_up_time=10^3)
