"""
TODO: Write docstring here.
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/bandwidth_wtih_memory"


# Params
num_trials = 10000::Int64
perc_range = (0.0, 0.05, 1.0)::Tuple{Float64, Float64, Float64}
grid_size = 10::Int64
time_depth = 8::Int64
num_pairs = 10::Int64
asynchronus_weight = 100::Int64

generate_new_data = true
if generate_new_data == true

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)

    # Extend graph in time without memory
    T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    plot_data = []
    error_data = []
    for i in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for memory percolation rate : $i")
        raw_data = []
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

            # Get the bandwidth of this quantity
            push!(raw_data, max_depth / max_depth_mem)
        end

        # Average the raw data, add it to plot data:
        push!(plot_data, mean(raw_data))
        # Get standard error
        push!(error_data, std(raw_data)/sqrt(num_trials - 1))
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, perc_range, grid_size, time_depth, num_pairs, asynchronus_weight, plot_data, error_data
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, perc_range, grid_size, time_depth, num_pairs, asynchronus_weight, plot_data, error_data = d
end

# Plot
x = collect(perc_range[1]:perc_range[2]:perc_range[3])
plot(x, plot_data, yerr = error_data, legend = false)
xaxis!(L"$\textrm{Proportion of Nodes with Quantum Memory}$")
yaxis!(L"$\textrm{R}$")

savefig("plots/bandwidth_with_memory_rate.png")
savefig("plots/bandwidth_with_memory_rate.pdf")
