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
generate_new_data = false
if generate_new_data == true

    # Params
    num_trials = 1000::Int64
    min_size = 5::Int64
    max_size = 25::Int64

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
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
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
plot(x, loss_arr1, seriestype = :scatter, label=L"$\eta_1$", xlims=(0, max_size), color = :red,
legend=:left, legendfontsize = 7, xguidefontsize = 10, tickfontsize = 10)
plot!(x, z_arr1, seriestype = :scatter, label=L"$F_1$", color =:red)
plot!(x, loss_arr2, seriestype = :scatter, label=L"$\eta_2$", color =:blue)
plot!(x, z_arr2, seriestype = :scatter, label=L"$F_2$", linestyle=:dash, color =:blue)
# [3:end]
plot!(x, loss_arr3, seriestype = :scatter, label=L"$\eta_3$", color =:green)
plot!(x, z_arr3, seriestype = :scatter, label=L"$F_3$", linestyle=:dash, color =:green)
plot!(x, loss_arr4, seriestype = :scatter, label=L"$\eta_3$", color =:purple)
plot!(x, z_arr4, seriestype = :scatter, label=L"$F_4$", linestyle=:dash, color =:purple)

# Plot analytic function for average cost:
function ave_pathlength(n)
    return 2/3 * n
end

function ave_1dlength(n)
    return (n+1)/3
end

ave_e = []
ave_f = []
for size in min_size:max_size
    e = dB_to_P(ave_pathlength(size))
    f = dB_to_Z(ave_pathlength(size))
    push!(ave_e, e)
    push!(ave_f, f)
end

plot!(x, ave_e, linewidth=2, label=L"$\textrm{ave } \eta$", color =:orange)
plot!(x, ave_f, linewidth=2, label=L"$\textrm{ave } F$", linestyle=:dash, color =:orange)

# # Get data for naive 2 path purification
# naive_e2 = []
# naive_f2 = []
# for size in min_size:max_size
#     e = dB_to_P(ave_pathlength(size))
#     f = dB_to_Z(ave_pathlength(size))
#     p = 2 / (size + 1)
#     epur, fpur = QuNet.purify(e, e, f, f)
#     push!(naive_e2, epur)
#     push!(naive_f2, fpur)
# end
# plot!(x, naive_e2, linewidth=2, label=L"$\textrm{Naive E2}$", linestyle=:dot, color =:blue)
# plot!(x, naive_f2, linewidth=2, label=L"$\textrm{Naive F2}$", linestyle=:dot, color =:blue)

# Get analytic data for 2 path purification
ave_e2 = []
ave_f2 = []
for size in min_size:max_size
    # Method 1
    # p = 2 / (size + 1)
    # e = dB_to_P(ave_pathlength(size))
    # eplus = dB_to_P(ave_pathlength(size) + 2)
    # f = dB_to_Z(ave_pathlength(size))
    # fplus = dB_to_Z(ave_pathlength(size) + 2)
    # e2, f2 = QuNet.purify(e, eplus, f, fplus) .* p .+ QuNet.purify(e, e, f, f) .* (1-p)

    # Method 2:
    # e = dB_to_P(ave_pathlength(size))
    # f = dB_to_Z(ave_pathlength(size))
    # eplus = dB_to_P(ave_pathlength(size) + 2)
    # fplus = dB_to_Z(ave_pathlength(size) + 2)
    # p = 2 / (size + 1)
    # e2, f2 = QuNet.purify(e, eplus*p + e*(1-p), f, fplus*p + f*(1-p))

    # Method 3
    p = 2 / (size + 1)
    e_dif = dB_to_P(ave_pathlength(size))
    f_dif = dB_to_Z(ave_pathlength(size))
    e_same = dB_to_P(ave_1dlength(size))
    e_same2 = dB_to_P(ave_1dlength(size) + 2)
    f_same = dB_to_Z(ave_1dlength(size))
    f_same2 = dB_to_Z(ave_1dlength(size) + 2)
    e_dif, f_dif = QuNet.purify(e_dif, e_dif, f_dif, f_dif)
    e_same, f_same = QuNet.purify(e_same, e_same2, f_same, f_same2)

    e2 = (1-p)*e_dif + p*e_same
    f2 = (1-p)*f_dif + p*f_same

    push!(ave_e2, e2)
    push!(ave_f2, f2)
end
plot!(x, ave_e2, linewidth=2, label=L"$\textrm{ave } F_2$", linestyle=:dot, color =:black)
plot!(x, ave_f2, linewidth=2, label=L"$\textrm{ave } F_2$", linestyle=:dot, color =:black)

xaxis!(L"$\textrm{Grid Size}$")
savefig("plots/cost_maxpaths.png")
savefig("plots/cost_maxpaths.pdf")

# Logarithmic plot

# # Plot efficiencies
# plot(x, loss_arr1, linewidth=2, label=L"$\eta_1$", xlims=(0, max_size), yaxis=:log, color = :red, legend=:left)
# plot!(x, loss_arr2, linewidth=2, label=L"$\eta_2$", yaxis=:log, color =:blue)
# plot!(x[3:end], loss_arr3[3:end], linewidth=2, label=L"$\eta_3$", yaxis=:log, color =:green)
# plot!(x[3:end], loss_arr4[3:end], linewidth=2, label=L"$\eta_4$", yaxis=:log, color =:purple)
#
# # # Plot fidelities
# z_arr1 = z_arr1 .- 0.5
# z_arr2 = z_arr2 .- 0.5
# z_arr3 = z_arr3 .- 0.5
# z_arr4 = z_arr4 .- 0.5
#
# plot!(x[1:end], z_arr1[1:end], linewidth=2, label=L"$F_1 - 0.5$", linestyle=:dash, color =:red, yaxis=:log)
# plot!(x[1:end], z_arr2[1:end], linewidth=2, label=L"$F_2 - 0.5$", linestyle=:dash, color =:blue, yaxis=:log)
# plot!(x[3:end], z_arr3[3:end], linewidth=2, label=L"$F_3 - 0.5$", linestyle=:dash, color =:green, yaxis=:log)
# plot!(x[3:end], z_arr4[3:end], linewidth=2, label=L"$F_4 - 0.5$", linestyle=:dash, color =:purple, yaxis=:log)
# xaxis!(L"$\textrm{Grid Size}$")
#
# savefig("plots/cost_maxpathslog.png")
# savefig("plots/cost_maxpathslog.pdf")
