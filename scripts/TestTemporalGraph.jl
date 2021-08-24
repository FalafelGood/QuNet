"""
Test costs for paths in an nxn grid lattice. Compare analysis with theory
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

function asymptotic_costs(gridsize::Int64)
    N = 1000
    G = GridNetwork(gridsize, gridsize)
    T = QuNet.TemporalGraph(G, 5, memory_costs = unit_costvector())
    p, dum1, dum2, dum3 = net_performance(T, N, 1, max_paths=4)
    return p["loss"], p["Z"]
end

depth = 50
num_trials = 5
num_pairs = 40
grid_size = 10

println("Collecting for time depth $depth")
G = GridNetwork(grid_size, grid_size)
# Create a Temporal Graph from G with timedepth i
T = QuNet.TemporalGraph(G, depth, memory_costs = zero_costvector())
# Get random pairs of asynchronus nodes
user_pairs = make_user_pairs(T, num_pairs)
# Get data
p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs, max_paths=4)
println(p)
println(p_e)
println(pat)
println(pat_e)

println("Getting asymptotic cost")
result = asymptotic_costs(grid_size)
println(result)
