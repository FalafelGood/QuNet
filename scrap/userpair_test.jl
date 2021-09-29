using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

num_trials = 1::Int64
grid_size = 5::Int64
time_depth = 5::Int64
num_pairs = 12::Int64
asynchronus_weight = 100::Int64
####### USERPAIR ########

# Generate ixi graph and extend it in time
G = GridNetwork(grid_size, grid_size)

raw_data = []
for j in 1:num_trials
    # Extend in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
    # Extend in time with memory links:
    T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = unit_costvector())


    # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
    mem_user_pairs = make_user_pairs(T, num_pairs, src_layer=1, dst_layer=-1)
    user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)

    # Add async nodes
    QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=asynchronus_weight)
    QuNet.add_async_nodes!(T, user_pairs, ϵ=asynchronus_weight)

    # Get pathset data
    pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, 4)
    pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs, 4)

    # Pathset is an array of vectors containing edges describing paths between end-user pairs
    # Objective: find the largest timedepth used in the pathsets

    max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
    max_depth = QuNet.max_timedepth(pathset, T)

    # Get the ratio of these two quantities. Add it to data array
    push!(raw_data, max_depth / max_depth_mem )
end

println("")
println(mean(raw_data))
