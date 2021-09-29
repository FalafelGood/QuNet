using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

num_trials = 100::Int64
perc = 1.
grid_size = 10::Int64
time_depth = 8::Int64
num_pairs = 50::Int64
asynchronus_weight = 100::Int64

##### MEMORY RATE #####
G = GridNetwork(grid_size, grid_size)

# Extend graph in time without memory

raw_data = []
for j in 1:num_trials
    # Extend graph in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
    # Make a network with some probability of memory
    T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = unit_costvector())

    # Get i random userpairs with asynchronus src and dst nodes.
    mem_user_pairs = make_user_pairs(T, num_pairs, src_layer=1, dst_layer=-1)
    user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)

    # Add async nodes
    QuNet.add_async_nodes!(T_mem, user_pairs, ϵ=asynchronus_weight)
    QuNet.add_async_nodes!(T, user_pairs, ϵ=asynchronus_weight)

    # Get pathset data
    # NOTE: the line below used to have mem_user_pairs as an argument.
    pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, 4)
    pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs, 4)

    max_depth_mem = QuNet.max_timedepth(pathset_mem, T)
    max_depth = QuNet.max_timedepth(pathset, T)

    # Get the bandwidth of this quantity
    push!(raw_data, max_depth / max_depth_mem)
end

println("Mean raw_data")
println(mean(raw_data))
