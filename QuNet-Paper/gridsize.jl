"""
Plot performance statistics of greedy-multi-path with respect to grid size of the network
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/gridsize"

# Params
# 500
num_trials = 500::Int64
num_pairs = 50::Int64
min_size = 10::Int64
#150
max_size = 150::Int64
# Increment constant
inc = 5::Int64

generate_new_data = true
if generate_new_data == true

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []
    # Numer of paths found by the last userpair
    last_count = []
    # Rate at which last user finds a path
    prob_last_nopath = []
    ave_path_distance = []
    ave_path_distance_err = []
    postman = []
    postman_err = []

    size_list = collect(min_size:inc:max_size)
    for i in size_list
        println("Collecting for gridsize: $i")
        # Generate ixi graph:
        net = GridNetwork(i, i, edge_costs=Dict("loss"=>1., "Z"=>1.))

        # Collect performance statistics
        p, p_e, pat, pat_e, lc, num_zeropath, apd, apd_err, post, post_err = net_performance(net, num_trials, num_pairs, max_paths=4, get_apd=true, get_postman=true)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
        push!(last_count, lc)
        push!(prob_last_nopath, num_zeropath/num_trials)
        push!(ave_path_distance, apd)
        push!(ave_path_distance_err, apd_err)
        push!(postman, post)
        push!(postman_err, post_err)
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, num_pairs, min_size, max_size, perf_data, perf_err, path_data, path_err, last_count, prob_last_nopath,
    ave_path_distance, ave_path_distance_err, postman, postman_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, num_pairs, min_size, max_size, perf_data, perf_err, path_data, path_err, last_count, prob_last_nopath, ave_path_distance, ave_path_distance_err, postman, postman_err = d
end

# Get values for x axis
x = collect(min_size:inc:max_size)

# Extract data from performance
loss = collect(map(x->x["loss"], perf_data))
z = collect(map(x->x["Z"], perf_data))
loss_err = collect(map(x->x["loss"], perf_err))
z_err = collect(map(x->x["Z"], perf_err))

# Extract from path data TODO (max_size - min_size)
P0 = [path_data[i][1]/num_pairs for i in 1:length(path_data)]
P1 = [path_data[i][2]/num_pairs for i in 1:length(path_data)]
P2 = [path_data[i][3]/num_pairs for i in 1:length(path_data)]
P3 = [path_data[i][4]/num_pairs for i in 1:length(path_data)]
P4 = [path_data[i][5]/num_pairs for i in 1:length(path_data)]

P0e = [path_err[i][1]/num_pairs for i in 1:length(path_err)]
P1e = [path_err[i][2]/num_pairs for i in 1:length(path_err)]
P2e = [path_err[i][3]/num_pairs for i in 1:length(path_err)]
P3e = [path_err[i][4]/num_pairs for i in 1:length(path_err)]
P4e = [path_err[i][5]/num_pairs for i in 1:length(path_err)]

##### Plot cost_gridsize #####
# color_palette = palette(:lightrainbow, 4)

ave_man_dist = ones(length(x))
ave_man_dist = 2/3 .* x
# for (idx, val) in enumerate(ave_man_dist)
#     # average manhattan distance for dim n := 2/3 * n
#     ave_man_dist = val * 2/3 * x[idx]
# end

# Convert ave_man_distance to costs:
e_scale = 0.1
f_scale = 0.1
ave_man_e = dB_to_P.(e_scale * ave_man_dist)
ave_man_f = dB_to_Z.(f_scale * ave_man_dist)

##### plot cost_gridsize #####
plot(x, loss, ylims=(0,1), seriestype=:scatter, yerror = loss_err, label=L"$\eta$",
legend=:topright, guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color=:DodgerBlue, markersize=5, markershape=:utriangle, xlims=(0,150))
plot!(x, ave_man_e, seriestype = :scatter, label=L"\textrm{Average manhattan } \eta",
markershape=:utriangle, markersize=5, color=:LightSkyBlue)
plot!(x, z, seriestype=:scatter, yerror = z_err, label=L"$F$", markersize=5,
color=:Crimson)
plot!(x, ave_man_f, seriestype = :scatter, label=L"\textrm{Average manhattan } F",
markersize=5, color=:Salmon)

# xaxis!(L"$\textrm{Grid Size}$")
yaxis!("Cost")
savefig("plots/cost_gridsize.png")
savefig("plots/cost_gridsize.pdf")


##### Plot log_cost_gridsize #####
plot(x, loss, ylims=(0,1), seriestype=:scatter, yerror = loss_err, label=L"$\eta$",
legend=:bottomleft, guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color=:DodgerBlue, markersize=5, markershape=:utriangle, xlims=(0,150), yaxis=(:log10, [10^-2.5, :auto]))
plot!(x, ave_man_e, seriestype = :scatter, label=L"\textrm{Average manhattan } \eta",
markershape=:utriangle, markersize=5, color=:LightSkyBlue)
plot!(x, z .- 0.5, seriestype=:scatter, yerror = z_err, label=L"$F$", markersize=5,
color=:Crimson)
plot!(x, ave_man_f .- 0.5, seriestype = :scatter, label=L"\textrm{Average manhattan } F",
markersize=5, color=:Salmon)

# xaxis!(L"$\textrm{Grid Size}$")
yaxis!("Cost")
savefig("plots/log_cost_gridsize.png")
savefig("plots/log_cost_gridsize.pdf")

# DEBUG
println("loss")
println(loss)
println("z")
println(z .- 0.5)
println("z_err")
println(z_err)


##### plot path_gridsize #####
plot(x, P0, seriestype=:scatter, yerr = P0e, label=L"$P_0$", legend= :right,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
color_palette = palette(:plasma, 5), markersize=5, xlims=(0,150))
plot!(x, P1, seriestype=:scatter, yerr = P1e, label=L"$P_1$", markersize=5)
plot!(x, P2, seriestype=:scatter, yerr = P2e, label=L"$P_2$", markersize=5)
plot!(x, P3, seriestype=:scatter, yerr = P3e, label=L"$P_3$", markersize=5)
plot!(x, P4, seriestype=:scatter, yerr = P4e, label=L"$P_4$", markersize=5)
# xaxis!(L"$\textrm{Grid Size}$")
yaxis!("Path rate")
xaxis!("Gridsize")
savefig("plots/path_gridsize.png")
savefig("plots/path_gridsize.pdf")

##### Plot prob_last_nopath #####
pathratio =  postman ./ ave_path_distance
pathratio_err = ((ave_path_distance_err ./ ave_path_distance) + (postman_err ./ postman)) .* pathratio

# Get standard error for Bernouli trials estimating probability of no path:
plnp_err = [sqrt(p*(1-p)/num_trials) for p in prob_last_nopath]
plot(x, prob_last_nopath, xlims=(0,150), ylims=(0,1.3), yerr = plnp_err, seriestype=:scatter, legend= :bottomleft,
xguidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
right_margin = 15Plots.mm, label="Path rate", markersize=5)

# xaxis!("Gridsize")
yaxis!("Rate that last pair does not find a path")

plot!(twinx(), x, pathratio, ylims = (0,1.3), yerr = pathratio_err, seriestype = :scatter,
color= :purple, ylabel="Ratio", label="Path ratio", legend = :bottomright, xticks=false,
tickfontsize=12, xguidefontsize=14, markersize=5)

savefig("plots/nopath_gridsize.png")
savefig("plots/nopath_gridsize.pdf")

##### Plot path_distance_gridsize #####
plot(x, ave_path_distance, yerr = ave_path_distance_err, seriestype=:scatter, legend= :topleft,
label="Average Manhattan distance", xguidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
markersize=5)
plot!(x, postman, yerr = postman_err, seriestype=:scatter, label="Average shortest path distance",
markersize=5)
# ave_man_dist = 2/3 .* x
# plot!(x, ave_man_dist, label = "Average Manhattan distance")

xaxis!("Gridsize")
yaxis!("Path distance")
# Plot pathratio with error
plot!(twinx(), x, pathratio, ylims = (0,2), yerr = pathratio_err, seriestype = :scatter,
color= :purple, ylabel="Test", label="Path ratio", legend = :bottomright, xticks=false)
savefig("plots/path_distance_gridsize.png")
savefig("plots/path_distance_gridsize.pdf")

# println("pathratio_err")
# println(pathratio_err)
