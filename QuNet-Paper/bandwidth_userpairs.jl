"""
Two different temporal plots, one with memory and one without. While varying the
number of end-users, we compare the ratio of the depths of the graphs
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/bandwidth_userpairs"

# Params
num_trials = 100::Int64
max_pairs = 10::Int64
grid_size = 10::Int64
time_depth = 5::Int64
asynchronus_weight = 100::Int64

generate_new_data = true
if generate_new_data == true

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)
    # Extend in time with memory links:
    T_mem = QuNet.TemporalGraph(G, time_depth, memory_costs = unit_costvector())
    # Extend in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    plot_data = []
    error_data = []
    for i in 1:max_pairs
        println("Collecting for pairs : $i")
        raw_data = []
        for j in 1:num_trials
            # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
            mem_user_pairs = make_user_pairs(T, i, src_layer=1, dst_layer=-1)
            user_pairs = make_user_pairs(T, i, src_layer=-1, dst_layer=-1)

            # Make copies of the network
            T_mem_copy = deepcopy(T_mem)
            T_copy = deepcopy(T)

            # Add async nodes
            QuNet.add_async_nodes!(T_mem_copy, mem_user_pairs, ϵ=asynchronus_weight)
            QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=asynchronus_weight)

            # Get pathset data
            pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem_copy, QuNet.purify, mem_user_pairs, 4)
            pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs, 4)
            # Pathset is an array of vectors containing edges describing paths between end-user pairs
            # Objective: find the largest timedepth used in the pathsets

            max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
            max_depth = QuNet.max_timedepth(pathset, T)

            # Get the ratio of these two quantities. Add it to data array
            push!(raw_data, max_depth / max_depth_mem )
        end
        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, plot_data, error_data
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, plot_data, error_data = d
end

# Plot
x = collect(1:max_pairs)
plot(x, plot_data, yerr = error_data, legend = false)
xaxis!(L"$\textrm{Number of End User Pairs}$")

savefig("plots/bandwidth_with_userpairs.png")
savefig("plots/bandwidth_with_userpairs.pdf")
