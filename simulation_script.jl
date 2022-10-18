using Accessors, LinearAlgebra, StatsBase, Plots, Random

include("src/GeneralizedJacksonSim.jl")
using .GeneralizedJacksonSim

include("test/scenarios.jl")  # some example network parameters
include("test/task3_test1.jl")
include("test/task3_test2.jl")

# when running this in VSCode, use the "Julia: Execute active File in REPL" option or plots
# won't show up

# some of the tests take a considerable amount of time for scenario4, so it has been
# excluded here

println("""An example network: here we have 3 queues in tandem, where jobs arrive to the
        first queue, move onto the 2nd and 3rd queues respectively, and then leave the
        system when they're done. Importantly, we require the network to be stable - that
        is, the arrival rate to each node λ_i is less than the service rate μ_i. The load
        for each node is defined as ρ_i = λ_i/μ_i, and we denote ρ* = max{ρ_i} as the
        "bottleneck load". Thus, we require ρ* < 1 for the network to be stable.\n""")

@show scenario1
ρ = compute_ρ(scenario1)
@show maximum(ρ)

println("""\nA quantity we may be interested in is the total steady state mean queue length.
        "Mean queue length" refers to the average length of the queue for each server over
        the entire time period, and "total" refers to the sum of the mean queue lengths of
        all servers. We can simulate running this scenario and obtain an estimate for the
        total steady state mean queue length:\n""")

@show sim_net(scenario1)

println("""\nWe can confirm this estimate by solving the traffic equations to obtain the
        theoretical mean queue length:\n""")

@show sum(ρ ./ (1 .- ρ))

println("\nVarying the bottleneck load ρ*:\n")

for ρ_star in [0.1, 0.5, 0.9]
    adjusted_scenario = set_scenario(scenario1, ρ_star)
    local ρ = compute_ρ(adjusted_scenario)
    println("ρ_star = $ρ_star:")
    @show sim_net(adjusted_scenario)
    @show sum(ρ ./ (1 .- ρ))
end

println("\nWe now introduce 2 more example scenarios:\n")

@show scenario2
@show scenario3

println("""Intuitively, the simulation should more closely align with the theoretical
        results the longer it runs. We can confirm this by observing the absolute relative
        error for different scenarios and different values of `max_time`:\n""")

task3_test1([scenario1, scenario2, scenario3])

println("""\nAnother quantity we may be interested in is the total (or mean) number of
        arrivals to any given node. Once again, we can obtain estimates by running the
        simulation, and verify these by solving the traffic equations to obtain λ:\n""")

task3_test2([scenario1, scenario2, scenario3])

println("""\nSomething else we can consider is the amount of time that customers spend in
        the system (also known as sojourn time). After finishing service at a job, a
        customer may either move to another job in the system, or exit the system (the
        probability of doing so is determined by the P matrix). To simulate this, we can
        keep track of every customer that arrives and record their arrival and departure
        times. We can then calculate e.g. the mean or median time spent in the system:\n""")

state = CustomerQueueNetworkState(scenario1)
sim_net_customers(scenario1, state=state)
sojourn_times = map((c) -> (c.departure - c.arrival), state.departed_customers)
@show mean(sojourn_times)
@show median(sojourn_times);
