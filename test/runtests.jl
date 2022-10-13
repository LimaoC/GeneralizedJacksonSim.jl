using Pkg
Pkg.activate(".")

include("../src/GeneralizedJacksonSim.jl")
using .GeneralizedJacksonSim

using Accessors, Plots, Random

include("test1.jl")