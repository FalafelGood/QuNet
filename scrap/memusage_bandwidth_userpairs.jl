"""
Two different temporal plots, one with memory and one without. While varying the
number of end-users, we compare the ratio of the depths of the graphs
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "scrap/memory_data"

# Params
# 1000
num_trials = 10::Int64
# 50
max_pairs = 50::Int64
# 10
grid_size = 10::Int64
# 20
time_depth = 20::Int64
asynchronus_weight = 10*eps(Float64)
# maxpaths=4

generate_new_data = true
if generate_new_data == true

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)
    # # Extend in time with memory links:
    # T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = unit_costvector())
    # # Extend in time without memory
    # T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    # How many memories were used when maxpaths = 4
    max_path_mem_usage = [[],[],[],[]]
    max_path_mem_error = [[],[],[],[]]
    nummaxpaths = 4

    for maxpaths in 1:nummaxpaths
        numdings = 0
        println("## Collecting for maxpath $maxpaths")
        for i in 1:max_pairs
            println("Collecting for pairs : $i")
            mem_counts = []

            for j in 1:num_trials
                # Extend in time with memory links:
                T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = zero_costvector())
                # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
                mem_user_pairs = make_user_pairs(T_mem, i, src_layer=-1, dst_layer=-1)
                # Add async node
                QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=asynchronus_weight)
                # Get pathset data
                pathset_mem, dum1, pathuse_count_mem = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, maxpaths)

                # Collect memory usage data
                memory_counter = 0
                for ps in pathset_mem
                    for path in ps
                        for edge in path
                            if edge.dst - edge.src == grid_size^2
                                memory_counter += 1
                            end
                        end
                    end
                    # println(memory_counter)
                    push!(mem_counts, memory_counter)
                end
            end

            # Get memory count statistics:
            push!(max_path_mem_usage[maxpaths], mean(mem_counts))
            push!(max_path_mem_error[maxpaths], std(mem_counts)/sqrt(num_trials-1))
        end
        # println("buffer")
        # println("numdings for max_paths $maxpaths: $numdings")
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, max_path_mem_usage, max_path_mem_error
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, max_path_mem_usage, max_path_mem_error = d
    # pathcount_data, pathcount_mem, pathcount_data_err, pathcount_mem_err = d
end

# Plot
x = collect(1:max_pairs)


plot(x, max_path_mem_usage[1], seriestype=:scatter, yerr = max_path_mem_error[1], label="max depth 1", legend=:topleft,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color_palette = palette(:Spectral_4, 4), markersize=5)
plot!(x, max_path_mem_usage[2], seriestype=:scatter, yerr = max_path_mem_error[2], label="max depth 2", markersize=5)
plot!(x, max_path_mem_usage[3], seriestype=:scatter, yerr = max_path_mem_error[3], label="max depth 3", markersize=5)
plot!(x, max_path_mem_usage[4], seriestype=:scatter, yerr = max_path_mem_error[4], label="max depth 4", markersize=5)

xaxis!("Number of user pairs")
yaxis!("Average # of memory channels used")
savefig("scrap/memory_usage.png")
savefig("scrap/memory_usage.pdf")
