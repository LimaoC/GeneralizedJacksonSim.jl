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
