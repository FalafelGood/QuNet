"""
Test costs for paths in an nxn grid lattice. Compare analysis with theory
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters


# Params
num_trials = 500::Int64
size = 20

# performance data
perf_data = []
# Generate network:
net = GridNetwork(size, size)
# Collect performance statistics for 1 userpair and 1 maxpath
performance, dummy, dummy, dummy = net_performance(net, num_trials, 1, max_paths=1)
push!(perf_data, performance)

# Extract data from performance data
loss_arr = collect(map(x->x["loss"], perf_data))
z_arr = collect(map(x->x["Z"], perf_data))

# TODO: This isn't strictly necessary, benchmarking does the averaging for us already.
ave_E = mean(loss_arr)
ave_Z = mean(z_arr)

# Analytic costs:
function ave_pathlength(n)
    return 2/3 * n
end

theory_E = dB_to_P(ave_pathlength(size))
theory_Z = dB_to_Z(ave_pathlength(size))

println("")
println("ave_E: $ave_E")
println("theory_E: $theory_E")
println("ave_Z: $ave_Z")
println("theory_Z: $theory_Z")
