"""
The first attempt Nathan and I made at IO
"""
using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using DelimitedFiles

"""
Plot the performance statistics of greedy_multi_path for 1 random end-user pair
over a range of graph sizes and for different numbers of max_path (1,2,3) (ie. the
maximum number of paths that can be purified by a given end-user pair.)
"""
file_path = "data/maxpaths.txt"
generate_new_data = true
if generate_new_data

    # Params
    num_trials = 50::Int64
    min_size = 2::Int64
    max_size = 20::Int64

    @assert min_size < max_size

    perf_data1 = []
    perf_data2 = []
    perf_data3 = []
    perf_data4 = []

    size_list = collect(min_size:1:max_size)
    for (j, data_array) in enumerate([perf_data1, perf_data2, perf_data3, perf_data4])
        println("Collecting for max_paths: $j")
        for i in size_list
            println("Collecting for gridsize: $i")
            # Generate ixi graph:
            net = GridNetwork(i, i)

            # Collect performance statistics
            performance, dummy, dummy, dummy = net_performance(net, num_trials, 1, max_paths=j)
            push!(data_array, performance)
        end
    end

    # Get values for x axis
    x = collect(min_size:1:max_size)

    # Extract data from performance data
    loss_arr1 = collect(map(x->x["loss"], perf_data1))
    z_arr1 = collect(map(x->x["Z"], perf_data1))
    loss_arr2 = collect(map(x->x["loss"], perf_data2))
    z_arr2 = collect(map(x->x["Z"], perf_data2))
    loss_arr3 = collect(map(x->x["loss"], perf_data3))
    z_arr3 = collect(map(x->x["Z"], perf_data3))
    loss_arr4 = collect(map(x->x["loss"], perf_data4))
    z_arr4 = collect(map(x->x["Z"], perf_data4))

    # Save data to txt
    save_variables = ["min_size" "max_size" "num_trials" "num_pairs" "perf_data1" "perf_data2" "perf_data3" "perf_data4"]
    open(file_path, "w") do io
        writedlm(io, save_variables)
        writedlm(io, [min_size,
                      max_size,
                      num_trials, # num_pairs
                      perf_data1,
                      perf_data2,
                      perf_data3,
                      perf_data4])
    end
# else
#     read_data = DelimitedFiles.readdlm(file_path)
#     variable_names = read_data[1]
#     min_size = read_data[2]
#     max_size = read_data[3]
#     num_trials = read_data[4]
#     num_pairs = read_data[5]
#     perf_data1 = read_data[6]
#     perf_data2 = read_data[7]
#     perf_data3 = read_data[8]
#     perf_data4 = read_data[9]

end

# Plot
plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), color = :red, legend=:left)
plot!(x, z_arr1, linewidth=2, label=L"$F_1$", linestyle=:dash, color =:red)
plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", color =:blue)
plot!(x, z_arr2, linewidth=2, label=L"$F_2$", linestyle=:dash, color =:blue)
plot!(x, loss_arr3, linewidth=2, label=L"$\eta_3$", color =:green)
plot!(x, z_arr3, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:green)
plot!(x, loss_arr4, linewidth=2, label=L"$\eta_3$", color =:purple)
plot!(x, z_arr4, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:purple)
xaxis!(L"$\textrm{Grid Size}$")

savefig("plots/cost_maxpaths.png")
savefig("plots/cost_maxpaths.pdf")

# Plot
plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), yaxis=:log, color = :red, legend=:left)
plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", yaxis=:log, color =:blue)
plot!(x[3:end], loss_arr3[3:end], linewidth=2, label=L"$\eta_3$", yaxis=:log, color =:green)
plot!(x[3:end], loss_arr4[3:end], linewidth=2, label=L"$\eta_3$", yaxis=:log, color =:purple)
xaxis!(L"$\textrm{Grid Size}$")

savefig("plots/cost_maxpathslog.png")
savefig("plots/cost_maxpathslog.pdf")
