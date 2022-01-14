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
max_pairs = 50::Int64
num_trials = 5000::Int64

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
    # Numer of paths found by the last userpair
    last_count = []
    # Rate at which last user finds a path
    prob_last_nopath = []

    grid_size = 10

    for i in 1:max_pairs
        println("Collecting for pairsize: $i")

        net = GridNetwork(grid_size, grid_size)

        # Collect performance statistics
        p, p_e, pat, pat_e, lc, num_zeropath = net_performance(net, num_trials, i, max_paths=4)
        push!(perf_data, p)
        push!(perf_err, p_e)
        push!(path_data, pat)
        push!(path_err, pat_e)
        push!(last_count, lc)
        push!(prob_last_nopath, num_zeropath/num_trials)
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
    @pack! d = max_pairs, num_trials, grid_size, perf_data, perf_err, path_data, last_count, prob_last_nopath, path_err, cpp, cpp_err, avepath
    save("$datafile.jld", "data", d)
else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack max_pairs, num_trials, grid_size, perf_data, perf_err, path_data, last_count, prob_last_nopath, path_err, cpp, cpp_err, avepath = d
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

##### Plot cost_userpair #####
# color_palette = palette(:lightrainbow, 4)
plot(x, loss, ylims=(0,1), seriestype = :scatter, yerror = loss_err, label=L"$\eta$",
legend=:topright, guidefontsize=14, tickfontsize=12, legendfontsize=10, fontfamily="computer modern",
color=:Dodgerblue, markersize=5, markershape=:utriangle)
# plot!(x, x./9 .* .093 .*(1 .-P0), label="average number that get path")
# xaxis!(L"$\textrm{Number of End User Pairs}$")
yaxis!("Costs")

# Collect and plot data for efficiency and fidelity per user pair
loss_per_user = []
for (n, e) in enumerate(loss)
    push!(loss_per_user, (1-P0[n])*e)
end
z_per_user = []
for (n, f) in enumerate(z)
    push!(z_per_user, (1-P0[n])*f)
end
plot!(x, z, seriestype = :scatter, yerror = z_err, label=L"$F$", markersize=5,
color = :Crimson)
plot!(x, loss_per_user, seriestype = :scatter, label=L"$\textrm{Unconditional } \eta$",
markersize=5, markershape=:utriangle, color=:LightSkyBlue)

# Try combining two plots:
# combo_per_user = loss_per_user .* z
# plot!(x, combo_per_user, seriestype = :scatter, label=L"$F \times \eta \textrm{ per user}$",
# markersize=4, markershape=:square, color=:mediumpurple)

savefig("plots/cost_userpair.png")
savefig("plots/cost_userpair.pdf")

##### Plot path_userpair #####
plot(x, P0, ylims=(0,1), seriestype=:scatter, yerr = P0e, label=L"$P_0$", legend= :right,
guidefontsize=14, tickfontsize=12, legendfontsize=10, fontfamily="computer modern",
color_palette = palette(:plasma, 5), markersize=5)
plot!(x, P1, seriestype=:scatter, yerr = P1e, label=L"$P_1$", markersize=5)
plot!(x, P2, seriestype=:scatter, yerr = P2e, label=L"$P_2$", markersize=5)
plot!(x, P3, seriestype=:scatter, yerr = P3e, label=L"$P_3$", markersize=5)
plot!(x, P4, seriestype=:scatter, yerr = P4e, label=L"$P_4$", markersize=5)
plot!(x, cpp, seriestype=:scatter, yerr = cpp_err, label=L"$P_{P}$", color=:MediumSpringGreen,
markersize=5)
yaxis!("Path probability")
xaxis!(L"$\textrm{Number of End User Pairs}$")
# xaxis!(L"$\textrm{Number of End User Pairs}$")
savefig("plots/path_userpair.png")
savefig("plots/path_userpair.pdf")

plot(x, avepath, linewidth=2, legend = false,
xguidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern")
xaxis!(L"$\textrm{Number of End User Pairs}$")
yaxis!(L"$\textrm{Average Number of Paths Used}$")
savefig("plots/avepath_userpair.png")
savefig("plots/avepath_userpair.pdf")

##### Plot nopath_rate #####
# yaxis=:log not working because zero -> -Inf log scale
plot(x[1:30], last_count[1:30], seriestype = :scatter, legend = false, yaxis=(:log10, [10^(-5), :auto]))
# println(last_count[1:30])
# plot(x, last_count, seriestype = :scatter, legend = false)
# xaxis!(L"$\textrm{Number of End User Pairs}$")
yaxis!(L"$\textrm{Number of Paths found by last pair}$")
savefig("plots/lastpair.png")
savefig("plots/lastpair.pdf")

function get_firstzero_loc(arr)
    for (idx, val) in enumerate(prob_last_nopath)
        if val == 1
            return idx
        end
    end
    return idx
end

first_zero = get_firstzero_loc(prob_last_nopath)

plot(x[1:first_zero], 1 .- prob_last_nopath[1:first_zero], seriestype = :scatter, legend = false,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern", markersize=5)
plot!(x[first_zero+1:max_pairs], 1 .- prob_last_nopath[first_zero+1:max_pairs], seriestype =:scatter,
legend = false, color=:white, markersize=5)
# xaxis!(L"$\textrm{Number of End User Pairs}$")
yaxis!(L"$\textrm{Rate that last pair finds path}$")

plot!(x[1:20], 1 .- prob_last_nopath[1:20], seriestype = :scatter, inset = (1, bbox(0.05, 0.05, 0.33, 0.33, :top, :right)),
subplot=2, legend=false, yaxis=(:log10, [10^(-5), :auto]))
# Plot a constant curve onto subplot:
# TODO:
savefig("plots/nopath_rate.png")
savefig("plots/nopath_rate.pdf")
# println(last_count)

# Simple graph saturation explanation?
plot(x, x.*(1 .-P0), label="average number of users that get a path")

# plot!(x[1:20], 1 .- prob_last_nopath[1:20], seriestype = :scatter, inset = (1, bbox(0.10, 0.10, 0.5, 0.5, :bottom, :left)))
