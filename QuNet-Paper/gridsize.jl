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
num_trials = 100::Int64
num_pairs = 1::Int64
min_size = 10::Int64
max_size = 20::Int64
# Increment constant
inc = 5::Int64

generate_new_data = true
if generate_new_data == true

    perf_data = []
    perf_err = []
    path_data = []
    path_err = []

    size_list = collect(min_size:inc:max_size)
    for i in size_list
        println("Collecting for gridsize: $i")
        # Generate ixi graph:
        net = GridNetwork(i, i)

        # Collect performance statistics
        p, p_e, pat, pat_e = net_performance(net, num_trials, num_pairs, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, num_pairs, min_size, max_size, perf_data, perf_err, path_data, path_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, num_pairs, min_size, max_size, perf_data, perf_err, path_data, path_err = d
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

# Plot
plot(x, loss, ylims=(0,1), linewidth=2, yerror = loss_err, label=L"$\eta$",
legend=:bottomright)
plot!(x, z, linewidth=2, yerror = z_err, label=L"$F$")
xaxis!(L"$\textrm{Grid Size}$")
savefig("plots/cost_gridsize.png")
savefig("plots/cost_gridsize.pdf")

plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
xaxis!(L"$\textrm{Grid Size}$")
savefig("plots/path_gridsize.png")
savefig("plots/path_gridsize.pdf")
