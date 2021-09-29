"""
Two different temporal plots, one with memory and one with some percolation rate.
While varying the percolation rate, we compare the ratio of the depths of the
graphs
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/bandwidth_wtih_memory"

# Params
num_trials = 500::Int64
perc_range = (0.00, 0.05, 1.00)::Tuple{Float64, Float64, Float64}
grid_size = 10::Int64
time_depth = 20::Int64
num_pairs = 50::Int64
asynchronus_weight = 100::Int64
maxpaths=4

generate_new_data = false
if generate_new_data == true

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)

    max_depth_data = [[],[],[],[]]
    max_depth_err = [[],[],[],[]]
    max_depth_mem_data = [[],[],[],[]]
    max_depth_mem_err = [[],[],[],[]]

    for maxpaths in 1:4
        println("## Collecting for maxpath $maxpaths")
        for i in perc_range[1]:perc_range[2]:perc_range[3]
            println("Collecting for memory percolation rate : $i")
            raw_max_depth = []
            raw_max_depth_mem = []
            for j in 1:num_trials
                # Extend in time without memory
                T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
                # Extend in time with memory links:
                T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=i, memory_costs = unit_costvector())


                # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
                user_pairs = make_user_pairs(T, num_pairs, src_layer=-1, dst_layer=-1)
                mem_user_pairs = make_user_pairs(T, num_pairs, src_layer=1, dst_layer=-1)

                # Add async nodes
                QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=asynchronus_weight)
                QuNet.add_async_nodes!(T, user_pairs, ϵ=asynchronus_weight)

                # Get pathset data
                pathset_mem, dum1, dum2 = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, maxpaths)
                pathset, dum1, dum2 = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs, maxpaths)
                # Pathset is an array of vectors containing edges describing paths between end-user pairs
                # Objective: find the largest timedepth used in the pathsets

                max_depth = QuNet.max_timedepth(pathset, T)
                max_depth_mem = QuNet.max_timedepth(pathset_mem, T)

                # Get the ratio of these two quantities. Add it to data array
                push!(raw_max_depth, max_depth)
                push!(raw_max_depth_mem, max_depth_mem)
            end

            # Average the raw data, add it to plot data:
            push!(max_depth_data[maxpaths], mean(raw_max_depth))
            push!(max_depth_err[maxpaths], std(raw_max_depth)/sqrt(num_trials-1))
            push!(max_depth_mem_data[maxpaths], mean(raw_max_depth_mem))
            push!(max_depth_mem_err[maxpaths], std(raw_max_depth)/sqrt(num_trials-1))
        end
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, perc_range, grid_size, time_depth, num_pairs, asynchronus_weight, plot_data, error_data,
    max_depth_data, max_depth_err, max_depth_mem_data, max_depth_mem_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, perc_range, grid_size, time_depth, num_pairs, asynchronus_weight, plot_data, error_data, max_depth_data, max_depth_err, max_depth_mem_data, max_depth_mem_err = d
end

# Plot
x = collect(perc_range[1]:perc_range[2]:perc_range[3])
# plot(x, plot_data, yerr = error_data, legend = false)

plot(x, max_depth_data[1], seriestype=:scatter, yerr = max_depth_err[1], label="max depth 1", legend=:topleft,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color_palette = palette(:Spectral_4, 4), markersize=5)
plot!(x, max_depth_data[2], seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth 2", markersize=5)
plot!(x, max_depth_data[3], seriestype=:scatter, yerr = max_depth_mem_err[3], label="max depth 3", markersize=5)
plot!(x, max_depth_data[4], seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth 4", markersize=5)
plot!(x, max_depth_mem_data[1], seriestype=:scatter, yerr = max_depth_mem_err[1], label="max depth with memory 1", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[2], seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth with memory 2", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[3], seriestype=:scatter, yerr = max_depth_mem_err[3], label="max depth with memory 3", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[4], seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth with memory 4", markershape=:utriangle, markersize=5)
xaxis!(L"$\textrm{Proportion of Nodes with Quantum Memory}$")
yaxis!("Time depth")

savefig("plots/bandwidth_with_memory_rate.png")
savefig("plots/bandwidth_with_memory_rate.pdf")
