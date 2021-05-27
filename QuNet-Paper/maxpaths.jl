"""
Performance statistics of greedy_multi_path for 1 random end-user pair
over a range of graph sizes and for different numbers of max_path (1,2,3) (ie. the
maximum number of paths that can be purified by a given end-user pair.)
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters


datafile = "data/maxpaths"
generate_new_data = true
if generate_new_data == true

    # Params
    num_trials = 500::Int64
    min_size = 10::Int64
    max_size = 50::Int64

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

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, min_size, max_size, perf_data1, perf_data2, perf_data3, perf_data4
    save("$datafile.jld", "$datafile", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["$datafile"]
    @unpack num_trials, min_size, max_size, perf_data1, perf_data2, perf_data3, perf_data4 = d
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

# Plot
plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), color = :red, legend=:left)
plot!(x, z_arr1, linewidth=2, label=L"$F_1$", linestyle=:dash, color =:red)
plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", color =:blue)
plot!(x, z_arr2, linewidth=2, label=L"$F_2$", linestyle=:dash, color =:blue)
plot!(x, loss_arr3, linewidth=2, label=L"$\eta_3$", color =:green)
plot!(x, z_arr3, linewidth=2, label=L"$F_3$", linestyle=:dash, color =:green)
plot!(x, loss_arr4, linewidth=2, label=L"$\eta_3$", color =:purple)
plot!(x, z_arr4, linewidth=2, label=L"$F_4$", linestyle=:dash, color =:purple)

# Plot analytic function for average cost:
function M(n)
    return 2/3 * n * (n^2 - 1) / (2 * n^2 - 1)
end

function E(n)
    return 10^(-M(n) / 10)
end

function F(n)
    return (10^(-M(n) / 10) + 1)/2
end
ave_e = E.(x)
ave_f = F.(x)
plot!(x, ave_e, linewidth=2, label=L"$\textrm{ave } \eta$", color =:orange)
plot!(x, ave_f, linewidth=2, label=L"$\textrm{ave } F$", linestyle=:dash, color =:orange)

xaxis!(L"$\textrm{Grid Size}$")

savefig("plots/cost_maxpaths.png")
savefig("plots/cost_maxpaths.pdf")

# Logarithmic plot
plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), yaxis=:log, color = :red, legend=:left)
plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", yaxis=:log, color =:blue)
plot!(x[3:end], loss_arr3[3:end], linewidth=2, label=L"$\eta_3$", yaxis=:log, color =:green)
plot!(x[3:end], loss_arr4[3:end], linewidth=2, label=L"$\eta_4$", yaxis=:log, color =:purple)

z_arr1 = z_arr1 .- 0.5
z_arr2 = z_arr2 .- 0.5
z_arr3 = z_arr3 .- 0.5
z_arr4 = z_arr4 .- 0.5

plot!(x[3:end], z_arr1[3:end], linewidth=2, label=L"$F_1 - 0.5$", linestyle=:dash, color =:red, yaxis=:log)
plot!(x[3:end], z_arr2[3:end], linewidth=2, label=L"$F_2 - 0.5$", linestyle=:dash, color =:blue, yaxis=:log)
plot!(x[3:end], z_arr3[3:end], linewidth=2, label=L"$F_3 - 0.5$", linestyle=:dash, color =:green, yaxis=:log)
plot!(x[3:end], z_arr4[3:end], linewidth=2, label=L"$F_4 - 0.5$", linestyle=:dash, color =:purple, yaxis=:log)
xaxis!(L"$\textrm{Grid Size}$")

savefig("plots/cost_maxpathslog.png")
savefig("plots/cost_maxpathslog.pdf")
