using Pkg
Pkg.activate(".")

include("../simulation_script.jl")

include("scenarios.jl")
include("task3_test1.jl")
include("task3_test2.jl")

scenarios = [scenario1, scenario2, scenario3, scenario4]

task3_test1(scenarios, verbose=false, multithreaded=true)
task3_test2(scenarios)
