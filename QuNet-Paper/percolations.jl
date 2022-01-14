"""
Plot the performance statistics of greedy-multi-path with respect to edge percolation
rate (The probability that a given edge is removed)
"""

using QuNet
using LaTeXStrings
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using JLD
using Parameters

datafile = "data/percolations"

# Params
num_pairs = 1::Int64
grid_size = 10::Int64
perc_range = (0.0, 0.01, 0.7)::Tuple{Float64, Float64, Float64}
# 5000
num_trials = 5000::Int64

generate_new_data = false
if generate_new_data == true

    net = GridNetwork(grid_size, grid_size)

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []
    ave_path_distance = []
    ave_path_distance_err = []
    postman = []
    postman_err = []

    for p in perc_range[1]:perc_range[2]:perc_range[3]
        println("Collecting for percolation rate: $p")

        # Percolate the network
        # perc_net = QuNet.percolate_edges(net, p)
        # refresh_graph!(perc_net)

        # Collect performance data with error, percolating the network edges
        p, p_e, pat, pat_e, dummy, dummy, apd, apd_err, post, post_err = net_performance(net, num_trials, num_pairs, max_paths=4,
        edge_perc_rate = p, get_apd=true, get_postman=true)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
        push!(ave_path_distance, apd)
        push!(ave_path_distance_err, apd_err)
        push!(postman, post)
        push!(postman_err, post_err)
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_pairs, grid_size, perc_range, num_trials, perf_data, perf_err, path_data, path_err, ave_path_distance,
    ave_path_distance_err, postman, postman_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_pairs, grid_size, perc_range, num_trials, perf_data, perf_err, path_data, path_err, ave_path_distance, ave_path_distance_err,
    postman, postman_err = d
end

# Get values for x axis
x = collect(perc_range[1]:perc_range[2]:perc_range[3])

# Extract performance data
loss = collect(map(x->x["loss"], perf_data))
z = collect(map(x->x["Z"], perf_data))
loss_err = collect(map(x->x["loss"], perf_err))
z_err = collect(map(x->x["Z"], perf_err))

# Extract data from path: PX is the rate of using X paths
P0 = [path_data[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P1 = [path_data[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P2 = [path_data[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P3 = [path_data[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P4 = [path_data[i][5]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

# Extract errors from path:
P0e = [path_err[i][1]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P1e = [path_err[i][2]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P2e = [path_err[i][3]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P3e = [path_err[i][4]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]
P4e = [path_err[i][5]/num_pairs for i in 1:length(perc_range[1]:perc_range[2]:perc_range[3])]

pathratio =  postman ./ ave_path_distance

##### Plot cost_percolation #####
msize = 5
# color_palette = palette(:lightrainbow, 4),
cost_percolations = plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"\eta",
legend=:top, guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
markersize=msize, size=(600,400), color = :Dodgerblue, markershape=:utriangle)
ylabel!("Costs")
plot!(x, z, seriestype = :scatter, yerror = z_err, markersize=msize, label=L"F",
color = :Crimson)
# Adding new ave_shortest_path costs
f = dB_to_Z.(ave_path_distance)
e = dB_to_P.(ave_path_distance)
plot!(x, f, linewidth=4, markersize=msize, label=L"$\textrm{Conditional Manhattan } F$",
color=:Tomato)
plot!(x, e, linewidth=4, markersize=msize, label=L"$\textrm{Conditional Manhattan } \eta$",
color=:LightSkyBlue)
# TODO: Try cost scaled by path_ratio
# xaxis!(L"$\textrm{Probability of Edge Removal}$")
savefig("plots/cost_percolation.pdf")
savefig("plots/cost_percolation.png")

##### Plot path_percolation #####
path_percolations = plot(x, P0, ylims=(0,1), seriestype=:scatter, yerr = P0e, label=L"$P_0$", legend= :right,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color_palette = palette(:plasma, 5), markersize=5)
yaxis!("Path probability")
plot!(x, P1, seriestype=:scatter, yerr = P1e, label=L"$P_1$", markersize=5)
plot!(x, P2, seriestype=:scatter, yerr = P2e, label=L"$P_2$", markersize=5)
plot!(x, P3, seriestype=:scatter, yerr = P3e, label=L"$P_3$", markersize=5)
plot!(x, P4, seriestype=:scatter, yerr = P3e, label=L"$P_4$", markersize=5)
xaxis!(L"$\textrm{Probability of Edge Removal}$")
savefig("plots/path_percolation.pdf")
savefig("plots/path_percolation.png")

# Plot ave_path_distance
# println(ave_path_distance)
# println(ave_path_distance_err)
# f = dB_to_Z.(ave_path_distance)
# e = dB_to_P.(ave_path_distance)
# plot(x, f, seriestype = :scatter, label="f", legend= true)
# plot!(x, e, seriestype = :scatter, label="e", legend= true)
# plot!(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$")
# plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")

##### Plot path_distance_percolation #####
path_distance_percolation = plot(x, ave_path_distance, yerr = ave_path_distance_err, seriestype = :scatter, label="Average Manhattan distance", legend = :bottomleft,
ylims = (0,10), right_margin = 15Plots.mm, guidefontsize=14, tickfontsize=12,
legendfontsize=8, fontfamily="computer modern", markersize=5, color=:orange)
ylabel!("Path distance")
plot!(x, postman, yerr=postman_err, seriestype = :scatter, label="Average shortest path distance",
markersize=5, color=:magenta)

# Plot ratio of postman with man
pathratio =  postman ./ ave_path_distance
pathratio_err = ((ave_path_distance_err ./ ave_path_distance) + (postman_err ./ postman)) .* pathratio
# plot!(twinx(), x, pathratio, yerr = pathratio_err, seriestype = :scatter, color= :pink,
# ylabel="Ratio", label="Path ratio", legend = :bottomright, guidefontsize=14, xticks=false, tickfontsize=12,
# ylims = (0,1.6), markersize=4, markershape=:square)
# ylabel!("Ratio")

# Plot horizontal line for ave manhattan distance for 10x10 grid:
mandist = ones(length(x)) .* 6.67
plot!(x, mandist, linewidth=2, label="Analytic Manhattan distance")
savefig("plots/path_distance_percolation.pdf")
savefig("plots/path_distance_percolation.png")

p_arr = []
for i in collect(1:length(x))
    D = ave_path_distance[i]
    M = postman[i]
    A = 2/3 * 10
    p= abs(D - A)/abs(D-M+A-1)
    push!(p_arr, p)
end
plot(x, p_arr)

##### PLOT BIG PERC
x_scale = 1
y_scale = 3
plot(cost_percolations, path_distance_percolation, path_percolations,
layout = (3,1), size = (x_scale * 600, y_scale * 400),
left_margin = 10Plots.mm, right_margin = 20Plots.mm)
savefig("plots/big_percolations.png")
savefig("plots/big_percolations.pdf")

# PLOT LOG COST PERCOLATION
##### Plot cost_percolation #####
msize = 4.
# x[msize, end]
color_palette = palette(:lightrainbow, 4),
plot(x, loss, ylims=(10^(-msize),1), seriestype = :scatter, yerror = loss_err, label=L"\eta",
legend=:top, guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
markersize=msize, size=(600,400), color = :Dodgerblue, markershape=:utriangle, yaxis=:log)
ylabel!("Costs")

# plot!(x, z, seriestype = :scatter, yerror = z_err, markersize=msize, label=L"F",
# color = :Crimson)
# Adding new ave_shortest_path costs
# f = dB_to_Z.(ave_path_distance)
# e = dB_to_P.(ave_path_distance)
# plot!(x, f, linewidth=4, markersize=msize, label=L"$\textrm{Conditional Manhattan } F$",
# color=:Tomato)
# plot!(x, e, linewidth=4, markersize=msize, label=L"$\textrm{Conditional Manhattan } \eta$",
# color=:LightSkyBlue)
# TODO: Try cost scaled by path_ratio
# xaxis!(L"$\textrm{Probability of Edge Removal}$")
