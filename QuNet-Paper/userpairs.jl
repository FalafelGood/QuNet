"""
Plot the performance statistics of greedy-multi-path vs the number of end-user pairs
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/userpairs"

# Params
max_pairs = 20::Int64
num_trials = 100::Int64

generate_new_data = false
if generate_new_data == true

    # The average routing costs between end-users sampled over num_trials for different numbers of end-users
    perf_data = []
    # The associated errors of the costs sampled over num_trials
    perf_err = []
    # Average numbers of paths used, sampled over num_trials for different numbers of end-users
    # e.g. [3,4,5]: 3 end-users found no path on average, 4 end-users found 1 path on average etc.
    path_data = []
    # Associated errors of path_data
    path_err = []

    grid_size = 10

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")

        net = GridNetwork(grid_size, grid_size)

        # Collect performance statistics
        p, p_e, pat, pat_e = net_performance(net, num_trials, i, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)

    end

    # Collect data for conditional probability of purification: (N2+N3)/∑N_i
    cpp = []
    cpp_err = []
    for i in 1:max_pairs
        tableau = path_data[i]
        errors = path_err[i]
        off = 1

        # Numerator and denominator
        num = tableau[2 + off] + tableau[3 + off] + tableau[4 + off]
        denom = tableau[1 + off] + tableau[2 + off] + tableau[3 + off] + tableau[4 + off]

        # Percentage errors (Ignore factor 100. Not needed)
        num_perr = (errors[2 + off] + errors[3 + off] + errors[4 + off])/num
        denom_perr = (errors[1 + off] + errors[2 + off] + errors[3 + off] + errors[4 + off])/denom

        data = num/denom
        data_err = (num_perr + denom_perr) * data
        push!(cpp, data)
        push!(cpp_err, data_err)
        i += 1
    end

    # Collect data for average number of paths used
    avepath = []
    for i in 1:max_pairs
        tableau = convert(Vector{Float64}, path_data[i])
        data = QuNet.ave_paths_used(tableau)

        # TODO: Include errors
        push!(avepath, data)
        i += 1
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = max_pairs, num_trials, grid_size, perf_data, perf_err, path_data, path_err, cpp, cpp_err, avepath
    save("$datafile.jld", "$datafile", d)
else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["$datafile"]
    @unpack max_pairs, num_trials, grid_size, perf_data, perf_err, path_data, path_err, cpp, cpp_err, avepath = d
end

# Get values for x axis
x = collect(1:max_pairs)

# Extract data from performance
loss = collect(map(x->x["loss"], perf_data))
z = collect(map(x->x["Z"], perf_data))
loss_err = collect(map(x->x["loss"], perf_err))
z_err = collect(map(x->x["Z"], perf_err))

# Extract data from path: PX is the rate of using X paths
P0 = [path_data[i][1]/i for i in 1:max_pairs]
P1 = [path_data[i][2]/i for i in 1:max_pairs]
P2 = [path_data[i][3]/i for i in 1:max_pairs]
P3 = [path_data[i][4]/i for i in 1:max_pairs]
P4 = [path_data[i][5]/i for i in 1:max_pairs]

P0e = [path_err[i][1]/i for i in 1:max_pairs]
P1e = [path_err[i][2]/i for i in 1:max_pairs]
P2e = [path_err[i][3]/i for i in 1:max_pairs]
P3e = [path_err[i][4]/i for i in 1:max_pairs]
P4e = [path_err[i][5]/i for i in 1:max_pairs]

# Plot
plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
legend=:bottomright)
plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$")
xaxis!(L"$\textrm{Number of End User Pairs}$")
savefig("plots/cost_userpair.png")
savefig("plots/cost_userpair.pdf")

plot(x, P0, ylims=(0,1), linewidth=2, yerr = P0e, label=L"$P_0$", legend= :right)
plot!(x, P1, linewidth=2, yerr = P1e, label=L"$P_1$")
plot!(x, P2, linewidth=2, yerr = P2e, label=L"$P_2$")
plot!(x, P3, linewidth=2, yerr = P3e, label=L"$P_3$")
plot!(x, P4, linewidth=2, yerr = P4e, label=L"$P_4$")
plot!(x, cpp, linewidth=2, yerr = cpp_err, label=L"$P_{P}$")
xaxis!(L"$\textrm{Number of End User Pairs}$")
savefig("plots/path_userpair.png")
savefig("plots/path_userpair.pdf")

plot(x, avepath, linewidth=2, legend = false)
xaxis!(L"$\textrm{Number of End User Pairs}$")
yaxis!(L"$\textrm{Average Number of Paths Used}$")
savefig("plots/avepath_userpair.png")
savefig("plots/avepath_userpair.pdf")
