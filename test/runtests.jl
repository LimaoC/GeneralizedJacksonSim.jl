using Pkg
Pkg.activate(".")

include("../simulation_script.jl")

include("scenarios.jl")
include("task3_test1.jl")


task3_test1(
    [scenario1, scenario2, scenario3, scenario4],
    verbose=false,
    multithreaded=true)
