using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/bandwidth_wtih_memory"

function get_bandwidth(i)
    # Params
    num_trials = 5::Int64
    grid_size = 10::Int64
    time_depth = 8::Int64
    num_pairs = 10::Int64
    asynchronus_weight = 100::Int64
    raw_data = []

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)

    # Extend graph in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    for j in 1:num_trials
    # Make a network with some probability of memory
        T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=i, memory_costs = unit_costvector())
        # Make a copy of the network without memory
        T_copy = deepcopy(T)

        # Get i random userpairs with asynchronus src and dst nodes.
        # mem_user_pairs = make_user_pairs(T_mem, num_pairs, src_layer=-1, dst_layer=-1)
        user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)

        # Add async nodes
        QuNet.add_async_nodes!(T_mem, user_pairs, ϵ=asynchronus_weight)
        QuNet.add_async_nodes!(T_copy, user_pairs, ϵ=asynchronus_weight)

        # Get pathset data
        # NOTE: the line below used to have mem_user_pairs as an argument.
        pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, user_pairs, 1)
        pathset, dum1, dum2 = QuNet.greedy_multi_path!(T_copy, QuNet.purify, user_pairs, 1)
        # Pathset is an array of vectors containing edges describing paths between end-user pairs
        # Objective: find the largest timedepth used in the pathsets

        max_depth_mem = QuNet.max_timedepth(pathset_mem, T_mem)
        max_depth = QuNet.max_timedepth(pathset, T_copy)

        println(max_depth_mem)
        println(max_depth)

        # Get the bandwidth of this quantity
        push!(raw_data, max_depth / max_depth_mem)
    end
    return mean(raw_data)
end

println("collecting for 1.")
println(get_bandwidth(1.))
