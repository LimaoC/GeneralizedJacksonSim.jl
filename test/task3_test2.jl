"""
This test compares the average number of arrivals to each node in the system from the
simulation, `sim_net()`, against the theoretical average number of arrivals.
"""

"""
    task3_test2(scenarios::Vector{NetworkParameters}; max_time::Int64=10^6,
                digits::Int64=3)

Prints the simulated average number of arrivals (rounded to `digits` decimal places) and
the theoretical average number of arrivals.
"""
function task3_test2(scenarios::Vector{NetworkParameters};
                     max_time::Int64=10^5, digits::Int64=3,
                     c_s_values::Vector{Float64}=[0.1, 0.5, 1.0, 2.0, 4.0])
    for (index, scenario) in enumerate(scenarios)
        println("Scenario $index:")
        for c_s in c_s_values
            println("   c_s = $c_s:")
            scenario = @set scenario.c_s = c_s
            # pass in a state to sim_net() so we have a reference to the state to calculate the
            # mean number of arrivals
            state = QueueNetworkState(scenario)
            _ = sim_net(scenario, state=state, max_time=max_time)

            # calculate mean number of arrivals
            mean_num_arrivals = state.arrivals ./ max_time
            theoretical_mean_num_arrivals = (I - scenario.P') \ scenario.α_vector
            sum_of_squares = sum((mean_num_arrivals - theoretical_mean_num_arrivals).^2)

            println("       Simulated average number of arrivals  : " *
                    "$(round.(mean_num_arrivals, digits=digits))")
            println("       Theoretical average number of arrivals: " *
                    "$(round.(theoretical_mean_num_arrivals, digits=digits))")
            println("       Sum of squared differences            : " *
                    "$(round.(sum_of_squares, digits=digits))")
        end
    end
end
