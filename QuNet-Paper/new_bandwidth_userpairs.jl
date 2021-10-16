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
num_trials = 1000::Int64
max_pairs = 50::Int64
grid_size = 10::Int64
time_depth = 20::Int64
asynchronus_weight = 0.001
# maxpaths=4

generate_new_data = true
if generate_new_data == true

    # Generate ixi graph and extend it in time
    G = GridNetwork(grid_size, grid_size)
    # # Extend in time with memory links:
    # T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = unit_costvector())
    # # Extend in time without memory
    # T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)

    max_depth_data = [[],[],[],[]]
    max_depth_err = [[],[],[],[]]
    max_depth_mem_data = [[],[],[],[]]
    max_depth_mem_err = [[],[],[],[]]

    pathcount_data = [[],[],[],[],[]]
    pathcount_data_err = [[],[],[],[],[]]
    pathcount_mem = [[],[],[],[],[]]
    pathcount_mem_err = [[],[],[],[],[]]

    nummaxpaths = 4

    for maxpaths in 1:nummaxpaths
        numdings = 0
        println("## Collecting for maxpath $maxpaths")

        raw_pathcount_data = []
        raw_pathcount_mem = []

        # DEBUG
        for i in 1:max_pairs
            println("Collecting for pairs : $i")
            raw_max_depth = []
            raw_max_depth_mem = []

            for j in 1:num_trials
                # Extend in time without memory
                T = QuNet.TemporalGraph(G, time_depth, memory_prob=0.0)
                # Extend in time with memory links:
                T_mem = QuNet.TemporalGraph(G, time_depth, memory_prob=1.0, memory_costs = zero_costvector())

                # Get i random userpairs. Ensure src nodes are fixed on T=1, dst nodes are asynchronus.
                user_pairs = make_user_pairs(T, i, src_layer=-1, dst_layer=-1)
                mem_user_pairs = make_user_pairs(T, i, src_layer=-1, dst_layer=-1)

                # Add async nodes
                QuNet.add_async_nodes!(T_mem, mem_user_pairs, ϵ=asynchronus_weight)
                QuNet.add_async_nodes!(T, user_pairs, ϵ=asynchronus_weight)

                # Get pathset data
                pathset_mem, dum1, pathuse_count_mem = QuNet.greedy_multi_path!(T_mem, QuNet.purify, mem_user_pairs, maxpaths)
                pathset, dum1, pathuse_count = QuNet.greedy_multi_path!(T, QuNet.purify, user_pairs, maxpaths)
                # Pathset is an array of vectors containing edges describing paths between end-user pairs
                # Objective: find the largest timedepth used in the pathsets

                max_depth = QuNet.max_timedepth(pathset, T)
                max_depth_mem = QuNet.max_timedepth(pathset_mem, T)

                if max_depth == time_depth
                    numdings += 1
                end

                if max_depth_mem == time_depth
                    numdings += 1
                end

                # Get the ratio of these two quantities. Add it to data array
                push!(raw_max_depth, max_depth)
                push!(raw_max_depth_mem, max_depth_mem)

                if maxpaths == nummaxpaths
                    push!(raw_pathcount_data, pathuse_count)
                    push!(raw_pathcount_mem, pathuse_count_mem)
                end
            end

            # get pathuse statistics:
            if maxpaths == nummaxpaths
                ave_pathcounts = [0.0 for i in 0:maxpaths+1]
                ave_pathcounts_err = [0.0 for i in 0:maxpaths+1]

                for i in 1:maxpaths+1
                    data = [raw_pathcount_data[j][i] for j in 1:num_trials]
                    data_mem = [raw_pathcount_data[j][i] for j in 1:num_trials]
                    push!(pathcount_data[i], mean(data))
                    push!(pathcount_data_err[i], std(data)/(sqrt(length(data))))
                    push!(pathcount_mem[i], mean(data_mem))
                    push!(pathcount_mem_err[i], std(data_mem)/(sqrt(length(data_mem))))
                end
            end

            # for i in 1:maxpaths+1
            #     data = [pathcount_data[j][i] for j in 1:num_trials]
            #     ave_pathcounts[i] = mean(data)
            #     ave_pathcounts_err[i] = std(data)/(sqrt(length(data)))
            # end

            # Average the raw data, add it to plot data:
            push!(max_depth_data[maxpaths], mean(raw_max_depth))
            push!(max_depth_err[maxpaths], std(raw_max_depth)/sqrt(num_trials-1))
            push!(max_depth_mem_data[maxpaths], mean(raw_max_depth_mem))
            push!(max_depth_mem_err[maxpaths], std(raw_max_depth)/sqrt(num_trials-1))
        end
        println("buffer")
        println("numdings for max_paths $maxpaths: $numdings")
    end

    # DEBUG
    # println(pathcount_data)
    # println(pathcount_mem)

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, plot_data, error_data, max_depth_data,
    max_depth_mem_data, max_depth_err, max_depth_mem_err, pathcount_data, pathcount_mem, pathcount_data_err, pathcount_mem_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, plot_data, error_data, max_depth_data, max_depth_mem_data, max_depth_err, max_depth_mem_err = d
    # pathcount_data, pathcount_mem, pathcount_data_err, pathcount_mem_err = d
end

# Plot
x = collect(1:max_pairs)
# plot(x, plot_data, yerr = error_data, legend = false)


plot(x, max_depth_data[1], seriestype=:scatter, yerr = max_depth_err[1], label="max depth 1", legend=:topleft,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color_palette = palette(:Spectral_4, 4), markersize=5)
plot!(x, max_depth_data[2], seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth 2", markersize=5)
plot!(x, max_depth_data[3], seriestype=:scatter, yerr = max_depth_mem_err[3], label="max depth 3", markersize=5)
plot!(x, max_depth_data[4], seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth 4", markersize=5)
# Spectral_4
# :imola
# :diverging_rainbow_bgymr_45_85_c67_n256
# plot!(x, max_depth_data[2] ./ last(max_depth_data[2]) .* last(max_depth_data[1]), seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth 2", markersize=5)
# plot!(x, max_depth_data[3] ./ last(max_depth_data[3]) .* last(max_depth_data[1]), seriestype=:scatter, yerr = max_depth_mem_err[3], label="max depth 3", markersize=5)
# plot!(x, max_depth_data[4] ./ last(max_depth_data[4]) .* last(max_depth_data[1]), seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth 4", markersize=5)
# alpha = 0.88
# beta = 0.84
# gamma = 0.83
# plot!(x, max_depth_data[2] ./ (2 .* alpha) , seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth 2", markersize=5)
# plot!(x, max_depth_data[3] ./ (3 .* beta) , seriestype=:scatter, label="max depth 3", markersize=5)
# plot!(x, max_depth_data[4] ./ (4 .* gamma) , seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth 4", markersize=5)

plot!(x, max_depth_mem_data[1], seriestype=:scatter, yerr = max_depth_mem_err[1], label="max depth with memory 1", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[2], seriestype=:scatter, yerr = max_depth_mem_err[2], label="max depth with memory 2", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[3], seriestype=:scatter, yerr = max_depth_mem_err[3], label="max depth with memory 3", markershape=:utriangle, markersize=5)
plot!(x, max_depth_mem_data[4], seriestype=:scatter, yerr = max_depth_mem_err[4], label="max depth with memory 4", markershape=:utriangle, markersize=5)
xaxis!("Number of user pairs")
yaxis!("Time depth")
savefig("plots/bandwidth_with_userpairs.png")
savefig("plots/bandwidth_with_userpairs.pdf")

# plot(x, pathcount_data[5], yerr=pathcount_data_err[5], seriestype=:scatter)
# plot!(x, pathcount_mem[5], yerr=pathcount_mem_err[5], seriestype=:scatter)
