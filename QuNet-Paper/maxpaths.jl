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
    # 1000
    num_trials = 10000::Int64
    min_size = 5::Int64
    max_size = 30::Int64

    @assert min_size < max_size

    perf_data1 = []
    perf_data2 = []
    perf_data3 = []
    perf_data4 = []

    path_data4 = []
    path_data4_err = []

    size_list = collect(min_size:1:max_size)
    for (j, data_array) in enumerate([perf_data1, perf_data2, perf_data3, perf_data4])
        println("Collecting for max_paths: $j")
        for i in size_list
            println("Collecting for gridsize: $i")
            # Generate ixi graph:
            net = GridNetwork(i, i)

            # Collect performance statistics
            performance, dummy, pat, pat_e = net_performance(net, num_trials, 1, max_paths=j)
            push!(data_array, performance)

            if j == 4
                push!(path_data4, pat)
                push!(path_data4_err, pat_e)
            end
        end
    end

    # Save data
    d = Dict{Symbol, Any}()
    @pack! d = num_trials, min_size, max_size, perf_data1, perf_data2, perf_data3, perf_data4, path_data4, path_data4_err
    save("$datafile.jld", "data", d)

else
    # Load data
    if !isfile("$datafile.jld")
        error("$datafile.jld not found in working directory")
    end
    d = load("$datafile.jld")["data"]
    @unpack num_trials, min_size, max_size, perf_data1, perf_data2, perf_data3, perf_data4, path_data4, path_data4_err = d
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

##### Plot cost_maxpaths #####
plot(x, loss_arr1, seriestype = :scatter, label=L"$\eta_1$", xlims=(0, max_size+11), color = :red,
markershape = :utriangle, legend=:best, guidefontsize=14, tickfontsize=12, legendfontsize=8,
fontfamily="computer modern", markersize=4)
plot!(x, z_arr1, seriestype = :scatter, label=L"$F_1$", color =:red)
plot!(x, loss_arr2, seriestype = :scatter, label=L"$\eta_2$", color =:blue, markershape=:utriangle)
plot!(x, z_arr2, seriestype = :scatter, label=L"$F_2$", color =:blue)
# [3:end]
plot!(x, loss_arr3, seriestype = :scatter, label=L"$\eta_3$", color =:green, markershape=:utriangle)
plot!(x, z_arr3, seriestype = :scatter, label=L"$F_3$", color =:green)
plot!(x, loss_arr4, seriestype = :scatter, label=L"$\eta_3$", color =:purple, markershape=:utriangle)
plot!(x, z_arr4, seriestype = :scatter, label=L"$F_4$", color =:purple)
yaxis!("Costs")

# Plot analytic function for average cost:
function ave_pathlength(n)
    return 2/3 * n
end

function ave_same(n)
    return (n+1)/3
end

function ave_dif(n)
    return 2*(1+n)/3
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
# ave_e2 = []
# ave_f2 = []

# 2 path-purification
ave_e2_best = []
ave_e2_worst = []
ave_f2_best = []
ave_f2_worst = []

# 3-path purification
ave_e3_worst = []
ave_f3_worst = []

# 4-path purification
ave_e4_worst = []
ave_f4_worst = []

for size in min_size:max_size
    # Method 1
    # p = 2 / (size + 1)
    # e = dB_to_P(ave_pathlength(size))
    # eplus = dB_to_P(ave_pathlength(size) + 2)
    # f = dB_to_Z(ave_pathlength(size))
    # fplus = dB_to_Z(ave_pathlength(size) + 2)
    # e2, f2 = QuNet.purify(e, eplus, f, fplus) .* p .+ QuNet.purify(e, e, f, f) .* (1-p)
    # # end of method 1

    # Method 2:
    # e = dB_to_P(ave_pathlength(size))
    # f = dB_to_Z(ave_pathlength(size))
    # eplus = dB_to_P(ave_pathlength(size) + 2)
    # fplus = dB_to_Z(ave_pathlength(size) + 2)
    # p = 2 / (size + 1)
    # e2, f2 = QuNet.purify(e, eplus*p + e*(1-p), f, fplus*p + f*(1-p))
    # # end of method 2

    # # Method 3
    # # Probability that pair lies on the same row or column
    # p = 2 / (size + 1)
    # # Average costs when users lie on different rows/columns
    # e_dif = dB_to_P(ave_dif(size))
    # f_dif = dB_to_Z(ave_dif(size))
    # # Average costs when users lie on same row/column
    # e_same = dB_to_P(ave_same(size))
    # f_same = dB_to_Z(ave_same(size))
    # # Average cost when users lie on same row/column plus two average edges
    # e_same2 = dB_to_P(ave_same(size) + 2)
    # f_same2 = dB_to_Z(ave_same(size) + 2)
    # # Average purification cost when users lie on different rows/columns
    # e_dif, f_dif = QuNet.purify(e_dif, e_dif, f_dif, f_dif)
    # # Average purification cost when same row/column
    # e_same, f_same = QuNet.purify(e_same, e_same2, f_same, f_same2)
    # e2 = (1-p)*e_dif + p*e_same
    # f2 = (1-p)*f_dif + p*f_same

    # Method 4: Best and worst case
    e_dif = dB_to_P(ave_dif(size))
    f_dif = dB_to_Z(ave_dif(size))
    # Average costs when users lie on same row/column
    e_same = dB_to_P(ave_same(size))
    f_same = dB_to_Z(ave_same(size))
    # Average cost when users lie on same row/column plus two average edges
    e_same2 = dB_to_P(ave_same(size) + 2)
    f_same2 = dB_to_Z(ave_same(size) + 2)
    # Average purification cost when users lie on different rows/columns
    e_worst, f_worst = QuNet.purify(e_dif, e_dif, f_dif, f_dif)
    # Average purification cost when same row/column
    e_best, f_best = QuNet.purify(e_same, e_same2, f_same, f_same2)

    push!(ave_e2_best, e_best)
    push!(ave_e2_worst, e_worst)
    push!(ave_f2_best, f_best)
    push!(ave_f2_worst, f_worst)

    e_dif4 = dB_to_P(ave_dif(size) + 4)
    f_dif4 = dB_to_Z(ave_dif(size) + 4)
    e_worst3, f_worst3 = QuNet.purify(e_dif4, e_worst, f_dif4, f_worst)
    e_worst4, f_worst4 = QuNet.purify(e_dif4, e_worst3, f_dif4, f_worst3)

    push!(ave_e3_worst, e_worst3)
    push!(ave_f3_worst, f_worst3)
    push!(ave_e4_worst, e_worst4)
    push!(ave_f4_worst, f_worst4)
end


# plot!(x, ave_e2_best, linewidth=2, label=L"$\textrm{Best case } E_2$", linestyle=:dot, color =:blue)
# plot!(x, ave_f2_best, linewidth=2, label=L"$\textrm{Best case } F_2$", linestyle=:dot, color =:blue)
plot!(x, ave_e2_worst, linewidth=2, label=L"$\textrm{Worst case } E_2$", color =:blue)
plot!(x, ave_f2_worst, linewidth=2, label=L"$\textrm{Worst case } F_2$", linestyle=:dot, color =:blue)
# Plot 3 path purification
plot!(x, ave_e3_worst, linewidth=2, label=L"$\textrm{Worst case } E_3$", color =:green)
plot!(x, ave_f3_worst, linewidth=2, label=L"$\textrm{Worst case } F_3$", linestyle=:dot, color =:green)
# Plot 4 path purification
plot!(x, ave_e4_worst, linewidth=2, label=L"$\textrm{Worst case } E_4$", color =:purple)
plot!(x, ave_f4_worst, linewidth=2, label=L"$\textrm{Worst case } F_4$", linestyle=:dot, color =:purple)

# plot!(x, ave_e2, linewidth=2, label=L"$\textrm{ave } F_2$", linestyle=:dot, color =:black)
# plot!(x, ave_f2, linewidth=2, label=L"$\textrm{ave } F_2$", linestyle=:dot, color =:black)

# xaxis!(L"$\textrm{Grid Size}$")
savefig("plots/cost_maxpaths.png")
savefig("plots/cost_maxpaths.pdf")


##### plot elog_cost_maxpaths #####
plot(x, loss_arr1, seriestype = :scatter, label=L"$\eta_1$", xlims=(0, max_size+11), color = :red,
markershape = :utriangle, legend=:best, guidefontsize=14, tickfontsize=12, legendfontsize=8,
fontfamily="computer modern", markersize=5, yaxis=:log)
# plot!(x, z_arr1 .- .5, seriestype = :scatter, label=L"$F_1$", color =:red)
plot!(x, loss_arr2, seriestype = :scatter, label=L"$\eta_2$", color =:yellow, markershape=:utriangle,
markersize=5)
# plot!(x, z_arr2 .- .5, seriestype = :scatter, label=L"$F_2$", color =:yellow)
# [3:end]
plot!(x, loss_arr3, seriestype = :scatter, label=L"$\eta_3$", color =:green, markershape=:utriangle,
markersize=5)
# plot!(x, z_arr3 .- .5, seriestype = :scatter, label=L"$F_3$", color =:green)
plot!(x, loss_arr4, seriestype = :scatter, label=L"$\eta_3$", color =:blue, markershape=:utriangle,
markersize=5)
# plot!(x, z_arr4 .- .5, seriestype = :scatter, label=L"$F_4$", color =:blue)
yaxis!("Costs")

plot!(x, ave_e, linewidth=2, label=L"$\textrm{Analytic } \eta$", color =:red)
# plot!(x, ave_f .- .5, linewidth=2, label=L"$\textrm{ave } F$", linestyle=:dash, color =:red)
# Plot 2 path purification
plot!(x, ave_e2_worst, linewidth=2, label=L"$\eta_2 \textrm{ Est.}$", color =:gold)
# plot!(x, ave_f2_worst .- .5, linewidth=2, label=L"$\textrm{Worst case } F_2$", linestyle=:dot, color =:yellow)
# # Plot 3 path purification
plot!(x, ave_e3_worst, linewidth=2, label=L"$\eta_3 \textrm{ Est.}$", color =:green)
# plot!(x, ave_f3_worst .- .5, linewidth=2, label=L"$\textrm{Worst case } F_3$", linestyle=:dot, color =:green)
# # Plot 4 path purification
plot!(x, ave_e4_worst, linewidth=2, label=L"$\eta_4 \textrm{ Est.}$", color =:blue)
# plot!(x, ave_f4_worst .- .5, linewidth=2, label=L"$\textrm{Worst case } F_4$", linestyle=:dot, color =:blue)

savefig("plots/elog_cost_maxpaths.png")
savefig("plots/elog_cost_maxpaths.pdf")

##### plot flog_cost_maxpaths #####
plot(x, z_arr1 .- .5, seriestype = :scatter, label=L"$F_1$", xlims=(0, max_size+11), color = :red,
legend=:best, guidefontsize=14, tickfontsize=12, legendfontsize=8,
fontfamily="computer modern", markersize=5, yaxis=:log)
plot!(x, z_arr2 .- .5, seriestype = :scatter, label=L"$F_2$", color =:yellow, markersize=5)
plot!(x, z_arr3 .- .5, seriestype = :scatter, label=L"$F_3$", color =:green, markersize=5)
plot!(x, z_arr4 .- .5, seriestype = :scatter, label=L"$F_4$", color =:blue, markersize=5)
plot!(x, ave_f .- .5, linewidth=2, label=L"$\textrm{Analytic } F$", color =:red)
plot!(x, ave_f2_worst .- .5, linewidth=2, label=L"$F_2 \textrm{ Est.} $", color =:gold)
plot!(x, ave_f3_worst .- .5, linewidth=2, label=L"$F_3 \textrm{ Est.}$", color =:green)
plot!(x, ave_f4_worst .- .5, linewidth=2, label=L"$F_4 \textrm{ Est.}$", color =:blue)

yaxis!("Costs")

savefig("plots/flog_cost_maxpaths.png")
savefig("plots/flog_cost_maxpaths.pdf")

# Average of purifications not purification of averages

# Method outline
# Given d, the gridsize, we consider a vertex on an infinite grid lattice
# and the set of all other vertices that lie within d steps.
# This set can be subdivided into the set of all points of distance one, two, etc from the central vertex
# To consider the average purification, we get the costs associated with pathlength 1
# And perform 2, 3, and 4 purification. We assume the worst case path lengths of
# L & L & 4+L & 4+L
# With these costs we calculate the mean, taking into account weights which result from
# The number of paths present (4*d paths)
# ave_e2 = []
# ave_f2 = []
# ave_e3 = []
# ave_f3 = []
# ave_e4 = []
# ave_f4 = []
#
# for max in min_size:max_size
#     e2_arr = []
#     f2_arr = []
#     e3_arr = []
#     f3_arr = []
#     e4_arr = []
#     f4_arr = []
#
#     for size in 1:max
#         num_paths = 4 * (size-1)
#         e = dB_to_P(Float64(size))
#         f = dB_to_Z(Float64(size))
#         ep4 = dB_to_P(Float64(size+4))
#         fp4 = dB_to_Z(Float64(size+4))
#
#         e2, f2 = QuNet.purify(e, e, f, f)
#         e3, f3 = QuNet.purify(e2, ep4, f2, fp4)
#         e4, f4 = QuNet.purify(e3, ep4, f3, fp4)
#
#         # Push once for each possible path
#         # This will balance out the averages later
#         for np in 1:num_paths
#             push!(e2_arr, e2)
#             push!(e3_arr, e3)
#             push!(e4_arr, e4)
#             push!(f2_arr, f2)
#             push!(f3_arr, f3)
#             push!(f4_arr, f4)
#         end
#     end
#     # Take averages of each
#     push!(ave_e2, mean(e2_arr))
#     push!(ave_e3, mean(e3_arr))
#     push!(ave_e4, mean(e4_arr))
#     push!(ave_f2, mean(f2_arr))
#     push!(ave_f3, mean(f3_arr))
#     push!(ave_f4, mean(f4_arr))
# end
#
# # Plot average of purifications
# plot(x, loss_arr1, seriestype = :scatter, label=L"$\eta_1$", xlims=(0, max_size), color = :red,
# legend=:best, legendfontsize = 7, xguidefontsize = 10, tickfontsize = 10)
# plot!(x, z_arr1, seriestype = :scatter, label=L"$F_1$", color =:red)
# plot!(x, loss_arr2, seriestype = :scatter, label=L"$\eta_2$", color =:blue)
# plot!(x, z_arr2, seriestype = :scatter, label=L"$F_2$", color =:blue)
# plot!(x, loss_arr3, seriestype = :scatter, label=L"$\eta_3$", color =:green)
# plot!(x, z_arr3, seriestype = :scatter, label=L"$F_3$", linestyle=:dash, color =:green)
# plot!(x, loss_arr4, seriestype = :scatter, label=L"$\eta_3$", color =:purple)
# plot!(x, z_arr4, seriestype = :scatter, label=L"$F_4$", linestyle=:dash, color =:purple)
#
# plot!(x, ave_e2, linewidth=2, label=L"$\textrm{Average } E_2$", linestyle=:dot, color =:blue)
# plot!(x, ave_f2, linewidth=2, label=L"$\textrm{Average } F_2$", linestyle=:dot, color =:blue)
# plot!(x, ave_e3, linewidth=2, label=L"$\textrm{Average } E_3$", linestyle=:dot, color =:black)
# plot!(x, ave_f3, linewidth=2, label=L"$\textrm{Average } F_3$", linestyle=:dot, color =:black)
# plot!(x, ave_e4, linewidth=2, label=L"$\textrm{Average } E_4$", linestyle=:dot, color =:purple)
# plot!(x, ave_f4, linewidth=2, label=L"$\textrm{Average } F_4$", linestyle=:dot, color =:purple)

# Average 2: Nathan's Method:

dif_e2 = []
dif_f2 = []
dif_e3 = []
dif_f3 = []
dif_e4 = []
dif_f4 = []

same_e2 = []
same_f2 = []
same_e3 = []
same_f3 = []
same_e4 = []
same_f4 = []

for size in min_size:max_size
    L = 2/3 * size
    e = dB_to_P(Float64(L))
    f = dB_to_Z(Float64(L))
    ep2 = dB_to_P(Float64(L+2))
    fp2 = dB_to_Z(Float64(L+2))
    ep4 = dB_to_P(Float64(L+4))
    fp4 = dB_to_Z(Float64(L+4))
    ep8 = dB_to_P(Float64(L+8))
    fp8 = dB_to_Z(Float64(L+8))

    e2, f2 = QuNet.purify(e, e, f, f)
    e3, f3 = QuNet.purify(e2, ep4, f2, fp4)
    e4, f4 = QuNet.purify(e3, ep4, f3, fp4)

    se2, sf2 = QuNet.purify(e, ep2, f, fp2)
    se3, sf3 = QuNet.purify(se2, ep2, sf2, fp2)
    se4, sf4 = QuNet.purify(se3, ep8, sf3, fp8)

    push!(dif_e2, e2)
    push!(dif_e3, e3)
    push!(dif_e4, e4)
    push!(dif_f2, f2)
    push!(dif_f3, f3)
    push!(dif_f4, f4)

    push!(same_e2, se2)
    push!(same_e3, se3)
    push!(same_e4, se4)
    push!(same_f2, sf2)
    push!(same_f3, sf3)
    push!(same_f4, sf4)
end

plot(x, loss_arr1, seriestype = :scatter, label=L"$\eta_1$", xlims=(0, max_size+10), color = :red,
legend=:best, legendfontsize = 7, xguidefontsize = 10, tickfontsize = 10, yaxis=:log)
plot!(x, z_arr1 .- .5, seriestype = :scatter, label=L"$F_1$", color =:red)
plot!(x, loss_arr2, seriestype = :scatter, label=L"$\eta_2$", color =:blue)
plot!(x, z_arr2 .- .5, seriestype = :scatter, label=L"$F_2$", color =:blue)
plot!(x, loss_arr3, seriestype = :scatter, label=L"$\eta_3$", color =:green)
plot!(x, z_arr3 .- .5, seriestype = :scatter, label=L"$F_3$", linestyle=:dash, color =:green)
plot!(x, loss_arr4, seriestype = :scatter, label=L"$\eta_3$", color =:purple)
plot!(x, z_arr4 .- .5, seriestype = :scatter, label=L"$F_4$", linestyle=:dash, color =:purple)

plot!(x, dif_e2, linewidth=2, label=L"$\textrm{Diff case } E_2$", linestyle=:dot, color =:blue)
plot!(x, dif_f2 .- .5, linewidth=2, label=L"$\textrm{Diff case } F_2$", linestyle=:dot, color =:blue)
plot!(x, dif_e3, linewidth=5, label=L"$\textrm{Diff case } E_3$", linestyle=:dot, color =:green)
plot!(x, dif_f3 .- .5, linewidth=2, label=L"$\textrm{Diff case } F_3$", linestyle=:dot, color =:green)
plot!(x, dif_e4, linewidth=2, label=L"$\textrm{Diff case } E_4$", linestyle=:dot, color =:purple)
plot!(x, dif_f4 .- .5, linewidth=2, label=L"$\textrm{Diff case } F_4$", linestyle=:dot, color =:purple)

plot!(x, same_e2, linewidth=2, label=L"$\textrm{Same case } E_2$", color =:blue)
plot!(x, same_f2 .- .5, linewidth=2, label=L"$\textrm{Same case } F_2$", color =:blue)
plot!(x, same_e3, linewidth=2, label=L"$\textrm{Same case } E_3$", color =:green)
plot!(x, same_f3 .- .5, linewidth=2, label=L"$\textrm{Same case } F_3$", color =:green)
plot!(x, same_e4, linewidth=2, label=L"$\textrm{Same case } E_4$", color =:purple)
plot!(x, same_f4 .- .5, linewidth=2, label=L"$\textrm{Same case } F_4$", color =:purple)

xaxis!(L"$\textrm{Grid Size}$")
savefig("plots/testcost_maxpaths.png")
savefig("plots/testcost_maxpaths.pdf")

# Plot path data:
P0 = [path_data4[i][1] for i in 1:length(path_data4)]
P1 = [path_data4[i][2] for i in 1:length(path_data4)]
P2 = [path_data4[i][3] for i in 1:length(path_data4)]
P3 = [path_data4[i][4] for i in 1:length(path_data4)]
P4 = [path_data4[i][5] for i in 1:length(path_data4)]

P0e = [path_data4_err[i][1] for i in 1:length(path_data4_err)]
P1e = [path_data4_err[i][2] for i in 1:length(path_data4_err)]
P2e = [path_data4_err[i][3] for i in 1:length(path_data4_err)]
P3e = [path_data4_err[i][4] for i in 1:length(path_data4_err)]
P4e = [path_data4_err[i][5] for i in 1:length(path_data4_err)]

##### Plot paths_maxpaths #####
# colorarray = (collect(0:length(P1)-1)./(length(P1)-1))
# palette([:purple, :green], 7)
# color_palette = cgrad(:rainbow, 4, categorical = true)
# cgrad(cs, [z], alpha = nothing, rev = false, scale = nothing, categorical = nothing)
# cgrad(:plasma, [0.1, 0.9])
plot(x, P1, yerr = P1e, seriestype = :scatter, label=L"P_1", xlims=(0, max_size+10),
color_palette = palette(:plasma, 4), legend=:topright,
guidefontsize=14, tickfontsize=12, legendfontsize=8, fontfamily="computer modern",
markersize=5)
# cgrad(:matter, 4, categorical = true)
#:jet
# Specral_10
# :seaborn_bright
# plot!(x, P1, yerr = P1e, seriestype = :scatter, label=L"P_1", markersize=5)
plot!(x, P2, yerr = P2e, seriestype = :scatter, label=L"P_2", markersize=5)
plot!(x, P3, yerr = P3e, seriestype = :scatter, label=L"P_3", markersize=5)
plot!(x, P4, yerr = P4e, seriestype = :scatter, label=L"P_4", markersize=5)

xlabel!("Gridsize")
ylabel!("Path rate")
savefig("plots/path_maxpaths.png")
savefig("plots/path_maxpaths.pdf")

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
