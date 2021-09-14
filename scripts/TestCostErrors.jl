"""
Test costs for paths in an nxn grid lattice. Compare analysis with theory
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters


# Params
num_trials = 3::Int64
size = 10
mpaths = 2

# performance data
perf_data = []
# Generate network:
net = GridNetwork(size, size)
# Collect performance statistics for 1 userpair and 1 maxpath
performance, dummy, dummy, dummy = net_performance(net, num_trials, 2, max_paths=mpaths)
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

theory_E2 = dB_to_P(ave_pathlength(size))
theory_Z2 = dB_to_Z(ave_pathlength(size))

theory_2E, theory_2Z = QuNet.purify(theory_E, theory_E2, theory_Z, theory_Z2)

# # Test purification on sample data set
# raw_path_statistics = (12., 11., 9., 3., 3., 10., 8., 8., 5., 4., 3., 12., 4., 9., 10., 1., 13.,
# 3., 8., 6., 3., 5., 10., 7., 8., 4., 10., 8., 3., 5., 8., 9., 8., 1., 5., 6., 10., 6., 6., 12., 12., 2., 10., 9.,
# 5., 3., 10.)
#
# pur_statistics = []
# for pathlength in raw_path_statistics
#     P = dB_to_P(pathlength)
#     Z = dB_to_Z(pathlength)
#     push!(pur_statistics, QuNet.purify_PBS(P, P, Z, Z))
# end
# # println(pur_statistics)
# pur_E_statistics = mean(collect(pur_statistics[i][1] for i in 1:length(pur_statistics)))
# ave_Z_statistics = mean(collect(pur_statistics[i][2] for i in 1:length(pur_statistics)))

println("")
println("ave_E: $ave_E")
println("theory_2E: $theory_2E")
println("ave_Z: $ave_Z")
println("theory_2Z: $theory_2Z")
# println("pur_E_statistics: $ave_E_statistics")
# println("pur_Z_statistics: $ave_Z_statistics")
