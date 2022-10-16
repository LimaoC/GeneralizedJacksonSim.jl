# Three queues in tandem
function get_scenario1()
    return NetworkParameters(
        L=3,
        α_vector=[0.5, 0, 0],
        μ_vector=ones(3),
        P=[0 1.0 0
           0 0 1.0
           0 0 0]
    )
end

# Three queues in tandem with option to return back to first queue
function get_scenario2()
    return NetworkParameters(
        L=3,
        α_vector=[0.5, 0, 0],
        μ_vector=ones(3),
        P=[0 1.0 0
           0 0 1.0
           0.3 0 0]
    )
end

# A ring of 5 queues
function get_scenario3()
    return NetworkParameters(
        L=5,
        α_vector=ones(5),
        μ_vector=collect(1:5),
        P=[0 0.8 0 0 0
            0 0 0.8 0 0
            0 0 0 0.8 0
            0 0 0 0 0.8
            0.8 0 0 0 0]
    )
end

# A large arbitrary network - generate some random (arbitrary) matrix P
function get_scenario4()
    Random.seed!(0)
    L = 100
    P = rand(L, L)
    P = P ./ sum(P, dims=2)  # normalize rows by the sum
    P = P .* (0.2 .+ 0.7rand(L))  # multiply rows by factors in [0.2,0.9] 

    return NetworkParameters(
        L=L,
        α_vector=ones(L),
        μ_vector=0.5 .+ rand(L),
        P=P
    )
end;

scenario1 = get_scenario1()
scenario2 = get_scenario2()
scenario3 = get_scenario3()
scenario4 = get_scenario4()

nothing
