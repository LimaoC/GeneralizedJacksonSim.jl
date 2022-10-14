"""
This test compares the total mean queue lengths from the simulation, `sim_net()`, against
the theoretical total mean queue lengths - specifically, the absolute relative error for
varying ρ* values.
"""

# Three queues in tandem
scenario1 = NetworkParameters(
    L=3,
    α_vector=[0.5, 0, 0],
    μ_vector=ones(3),
    P=[0 1.0 0
        0 0 1.0
        0 0 0])

# Three queues in tandem with option to return back to first queue
scenario2 = @set scenario1.P = [  # The @set macro is from Accessors.jl and allows to
    0 1.0 0                       # easily make a modified copy of an (immutable) struct
    0 0 1.0
    0.3 0 0]

# A ring of 5 queues
scenario3 = NetworkParameters(
    L=5,
    α_vector=ones(5),
    μ_vector=collect(1:5),
    P=[0 0.8 0 0 0
        0 0 0.8 0 0
        0 0 0 0.8 0
        0 0 0 0 0.8
        0.8 0 0 0 0])

# A large arbitrary network - generate some random (arbitrary) matrix P
Random.seed!(0)
L = 100
P = rand(L, L)
P = P ./ sum(P, dims=2)  # normalize rows by the sum
P = P .* (0.2 .+ 0.7rand(L))  # multiply rows by factors in [0.2,0.9] 

scenario4 = NetworkParameters(
    L=L,
    α_vector=ones(L),
    μ_vector=0.5 .+ rand(L),
    P=P);

function sim_test(net::NetworkParameters, scenario_number::Int64;
                  max_time::Int = 10^5, warm_up_time::Int = 10^3, verbose::Bool = false,
                  multithreaded::Bool = false)
    ρ_star_values = 0.1:0.01:0.9
    simulated_total_mean_queue_lengths = zeros(length(ρ_star_values))
    absolute_relative_errors = zeros(length(ρ_star_values))

    if multithreaded
        Threads.@threads for index in eachindex(ρ_star_values)
            ρ_star = ρ_star_values[index]
            verbose && println("Starting ρ* = $ρ_star in thread $(Threads.threadid())")

            # adjust network parameters to suit this ρ*
            adjusted_net = set_scenario(net, ρ_star)
            ρ = compute_ρ(adjusted_net)

            # calculate and simulate total mean queue lengths
            theoretical = sum(ρ ./ (1 .- ρ))
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)

            # save lengths to array
            simulated_total_mean_queue_lengths[index] = simulated
            absolute_relative_errors[index] = abs(theoretical - simulated) / theoretical

            println("Done with ρ* = $ρ_star")
        end
    else
        # single-thread
        for (index, ρ_star) in enumerate(ρ_star_values)
            println("Starting ρ* = $ρ_star")

            # adjust network parameters to suit this ρ*
            adjusted_net = set_scenario(net, ρ_star)
            ρ = compute_ρ(adjusted_net)

            # calculate and simulate total mean queue lengths
            theoretical = sum(ρ ./ (1 .- ρ))
            simulated = sim_net(adjusted_net, max_time=max_time, warm_up_time=warm_up_time)

            # save lengths to array
            simulated_total_mean_queue_lengths[index] = simulated
            absolute_relative_errors[index] = abs(theoretical - simulated) / theoretical

            println("Done with ρ* = $ρ_star")
        end
    end

    plot(
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

p1_sim, p1_err = sim_test(scenario1, 1, verbose=true, multithreaded=true)
println("scenario1: done")
p2_sim, p2_err = sim_test(scenario2, 2, verbose=true, multithreaded=true)
println("scenario2: done")
p3_sim, p3_err = sim_test(scenario3, 3, verbose=true, multithreaded=true)
println("scenario3: done")
p4_sim, p4_err = sim_test(scenario4, 4, verbose=true, multithreaded=true)
println("scenario4: done")
plot(
    p1_sim, p1_err, p2_sim, p2_err, p3_sim, p3_err, p4_sim, p4_err,
    layout=(4, 2), legend=false, size=(1000, 1000)
)
