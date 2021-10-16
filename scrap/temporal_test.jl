"""
TEST FILE FOR VARIOUS TEMPORAL META GRAPH THINGS
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/timedepth_test"

num_trials = 100::Int64
min_depth = 5
max_depth = 10::Int64
num_pairs = 50::Int64
grid_size = 10::Int64
async_cost = 0.01
src_layer= 5
dst_layer= -1

perf_data = []
perf_err = []
path_data = []
path_err = []

for i in min_depth:max_depth

    # Debug
    # global dst_layer
    # if dst_layer >= i
    #     spcl_dst_layer = i
    # else
    #     spcl_dst_layer = dst_layer
    # end

    # global src_layer
    # if src_layer < i
    #     spcl_src_layer = i
    # else
    #     spcl_src_layer = src_layer
    # end

    println("Collecting for time depth $i")
    G = GridNetwork(grid_size, grid_size)
    # Create a Temporal Graph from G with timedepth i
    T = QuNet.TemporalGraph(G, i, memory_costs = zero_costvector())
    # Get random pairs of asynchronus nodes
    user_pairs = make_user_pairs(T, num_pairs)
    # Get data
    p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs, max_paths=4,
    async_cost=async_cost, src_layer=src_layer, dst_layer=dst_layer)
    push!(perf_data, p)
    push!(perf_err, p_e)
    push!(path_data, pat)
    push!(path_err, pat_e)
end

# Collect data for horizontal lines:
# println("Collecting data for asymptote")
# as = asymptotic_costs(grid_size)
# e_as = ones(length(min_depth:max_depth)) * as[1]
# f_as = ones(length(min_depth:max_depth)) * as[2]

# Get values for x axis
# x = collect(1:(max_depth-min_depth))
x = collect(min_depth:max_depth-1)

# Extract from performance data
loss = collect(map(x->x["loss"], perf_data))
z = collect(map(x->x["Z"], perf_data))
loss_err = collect(map(x->x["loss"], perf_err))
z_err = collect(map(x->x["Z"], perf_err))

# Extract from path data
P0 = [path_data[i][1]/num_pairs for i in 1:(max_depth-min_depth)]
P1 = [path_data[i][2]/num_pairs for i in 1:(max_depth-min_depth)]
P2 = [path_data[i][3]/num_pairs for i in 1:(max_depth-min_depth)]
P3 = [path_data[i][4]/num_pairs for i in 1:(max_depth-min_depth)]
P4 = [path_data[i][5]/num_pairs for i in 1:(max_depth-min_depth)]

# P0e = [path_err[i][1]/num_pairs for i in 1:(max_depth-min_depth)]
# P1e = [path_err[i][2]/num_pairs for i in 1:(max_depth-min_depth)]
# P2e = [path_err[i][3]/num_pairs for i in 1:(max_depth-min_depth)]
# P3e = [path_err[i][4]/num_pairs for i in 1:(max_depth-min_depth)]
# P4e = [path_err[i][5]/num_pairs for i in 1:(max_depth-min_depth)]

println(P0)
println(P1)
println(P2)
println(P3)
println(P4)

# Plot
# after seriestype: marker = (5)
plot(x, loss, ylims=(0,1), xlims=(min_depth, max_depth), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
legend=:right, xguidefontsize=14, tickfontsize=12, legendfontsize=10, fontfamily="computer modern",
markersize=5, color=:DodgerBlue, markershape =:utriangle)
plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$", markersize=5, color=:Crimson)

# Plot asymptote
# plot!(x, e_as, linestyle=:dot, color=:blue, linewidth=2, label=L"$\textrm{Asymptotic } \eta$")
# plot!(x, f_as, linestyle=:dot, color=:red, linewidth=2, label=L"$\textrm{Asymptotic } F$")
xaxis!(L"$\textrm{Time Depth of Tempral Meta-Graph}$")

savefig("scrap/test_costtemporal.png")

plot(x, P0, ylims=(0,1), xlims=(min_depth, max_depth), seriestype=:scatter, yerr = P0e, label=L"$P_0$", legend= :right,
xguidefontsize=14, tickfontsize=12, legendfontsize=10, fontfamily="computer modern",
markersize=5, color_palette = palette(:plasma, 10))
plot!(x, P0, linewidth=1, label=false)
plot!(x, P1, seriestype=:scatter, yerr = P1e, label=L"$P_1$", markersize=5)
plot!(x, P1, linewidth=1, label=false)
plot!(x, P2, seriestype=:scatter, yerr = P2e, label=L"$P_2$", markersize=5)
plot!(x, P2, linewidth=1, label=false)
plot!(x, P3, seriestype=:scatter, yerr = P3e, label=L"$P_3$", markersize=5)
plot!(x, P3, linewidth=1, label=false)
plot!(x, P4, seriestype=:scatter, yerr = P4e, label=L"$P_4$", markersize=5)
plot!(x, P4, linewidth=1, label=false)
xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")

savefig("scrap/test_pathtemporal.png")
