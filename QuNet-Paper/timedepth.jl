"""
For a given grid size, this function runs the greedy_multi_path routing algorithm
on randomly placed end-user pairs.
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

function asymptotic_costs(gridsize::Int64)
    N = 100
    G = GridNetwork(gridsize, gridsize)
    T = QuNet.TemporalGraph(G, 5, memory_costs = unit_costvector())
    p, dum1, dum2, dum3 = net_performance(T, N, 1, max_paths=4)
    return p["loss"], p["Z"]
end

datafile = "data/timedepth"

# Params
num_trials = 1000::Int64
max_depth = 15::Int64
num_pairs = 40::Int64
grid_size = 10::Int64

generate_new_data = true
if generate_new_data == true

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []

    for i in 1:max_depth
        println("Collecting for time depth $i")
        G = GridNetwork(grid_size, grid_size)
        # Create a Temporal Graph from G with timedepth i
        T = QuNet.TemporalGraph(G, i, memory_costs = unit_costvector())
        # Get random pairs of asynchronus nodes
        user_pairs = make_user_pairs(T, num_pairs)
        # Get data
        p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Collect data for horizontal lines:
    println("Collecting data for asymptote")
    as = asymptotic_costs(grid_size)
    e_as = ones(length(1:max_depth)) * as[1]
    f_as = ones(length(1:max_depth)) * as[2]

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, max_depth, num_pairs, grid_size, perf_data, perf_err, path_data, path_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, max_depth, num_pairs, grid_size, perf_data, perf_err, path_data, path_err = d
end

# Get values for x axis
x = collect(1:max_depth)

# Extract from performance data
loss = collect(map(x->x["loss"], perf_data))
z = collect(map(x->x["Z"], perf_data))
loss_err = collect(map(x->x["loss"], perf_err))
z_err = collect(map(x->x["Z"], perf_err))

# Extract from path data
P0 = [path_data[i][1]/num_pairs for i in 1:max_depth]
P1 = [path_data[i][2]/num_pairs for i in 1:max_depth]
P2 = [path_data[i][3]/num_pairs for i in 1:max_depth]
P3 = [path_data[i][4]/num_pairs for i in 1:max_depth]
P4 = [path_data[i][5]/num_pairs for i in 1:max_depth]

P0e = [path_err[i][1]/num_pairs for i in 1:max_depth]
P1e = [path_err[i][2]/num_pairs for i in 1:max_depth]
P2e = [path_err[i][3]/num_pairs for i in 1:max_depth]
P3e = [path_err[i][4]/num_pairs for i in 1:max_depth]
P4e = [path_err[i][5]/num_pairs for i in 1:max_depth]

# Plot
# after seriestype: marker = (5)
plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
legend=:right)
plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")

# Plot asymptote
plot!(x, e_as, linestyle=:dot, color=:red, linewidth=2, label=L"$\textrm{Asymptotic } \eta$")
plot!(x, f_as, linestyle=:dot, color=:green, linewidth=2, label=L"$\textrm{Asymptotic } F$")
xaxis!(L"$\textrm{Time Depth of Tempral Meta-Graph}$")

savefig("plots/cost_temporal.png")
savefig("plots/cost_temporal.pdf")

plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
xaxis!(L"$\textrm{Time Depth of Temporal Meta-Graph}$")

savefig("plots/path_temporal.png")
savefig("plots/path_temporal.pdf")
