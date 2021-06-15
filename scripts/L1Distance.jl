"""
Check what average L1 distance is for two random vertices
in a grid graph of variable size.
"""

using LightGraphs
using QuNet
using Statistics
using Plots

function make_userpairs(num_nodes::Int, num_pairs::Int; node_list=nothing)::Vector{Tuple{Int64, Int64}}
    @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
    if node_list != nothing
        rand_space = node_list
    else
        rand_space = Array(collect(1:num_nodes))
    end
    pairs = Vector{Tuple}()
    i = 0
    while i < num_pairs
        idx = rand(1:length(rand_space))
        u = rand_space[idx]
        deleteat!(rand_space, idx)
        idx = rand(1:length(rand_space))
        v = rand_space[idx]
        deleteat!(rand_space, idx)
        chosen_pair = (u, v)
        push!(pairs, chosen_pair)
        i += 1
    end
    return pairs
end

# Params
numSamples = 10000
minDim = 2
maxDim = 10
makeNewData = true

# MAIN
if makeNewData == true
    pathLengths = [[] for i in minDim:maxDim]
    for sample in 1:numSamples

        for (dimidx, dim) in enumerate(minDim:maxDim)
            g = LightGraphs.grid([dim, dim])
            # Make one userpair
            dummy = make_userpairs(nv(g), 1)
            pair = dummy[1]

            shortestPath = a_star(g, pair[1], pair[2])
            len = length(shortestPath)
            push!(pathLengths[dimidx], len)
        end
    end

    L1 = []
    for dimLength in pathLengths
        path = mean(dimLength)
        push!(L1, path)
    end
end

analyticL1 = []
HL1 = []

function PaperL1(n::Int)::Float64
    return 2/3 * n*(n^2 - 1) / (2*n^2 - 1)
end

function HudsonL1(n::Int)::Float64
    # return (2/3 * n*(n^2 -1) + n^2*(n+1))/(2*n^2 - 1)
    return (2/3 * n*(n^2 - 1)*(n-1)^2 + n^2*(n + 1)) / (n^2 * (n^2 - 1))
end

for n in minDim:maxDim
    push!(analyticL1, PaperL1(n))
    push!(HL1, HudsonL1(n))
end

println(L1)
println(analyticL1)
x = collect(minDim:maxDim)
plot(x, L1, label = "L1")
plot!(x, analyticL1, label = "Analytic L1")
plot!(x, HL1, label = "Hudson's L1")
xlabel!("grid size")
ylabel!("Path length")
