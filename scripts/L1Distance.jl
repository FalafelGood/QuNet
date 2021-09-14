"""
Check what average L1 distance is for two random vertices
in a grid graph of variable size.
"""

using LightGraphs
using QuNet
using Statistics
using Plots

function make_userpairs(path_length::Int)
    p1 = rand(1:path_length)
    p2 = rand(1:path_length)
    while p2 == p1
        p2 = rand(1:path_length)
    end
    return p1, p2
end

# Params
numSamples = 10000
minDim = 2
maxDim = 40
makeNewData = true

# MAIN
if makeNewData == true
    lengths = [[] for i in minDim:maxDim]
    for (dimidx, dim) in enumerate(minDim:maxDim)
        for sample in 1:numSamples
            g = LightGraphs.path_graph(dim)
            p1, p2 = make_userpairs(dim)
            shortestPath = a_star(g, p1, p2)
            len = length(shortestPath)
            push!(lengths[dimidx], len)
        end
    end

    L1 = []
    for l in lengths
        path = mean(l)
        push!(L1, path)
    end
end

HL1 = []

function HudsonL1(n::Int)::Float64
    # return (2/3 * n*(n^2 -1) + n^2*(n+1))/(2*n^2 - 1)
    return 1/3 * (n+1)
end

for n in minDim:maxDim
    push!(HL1, HudsonL1(n))
end

println("Experimental data")
println(L1)
println("Analytic data")
println(HL1)
x = collect(minDim:maxDim)
plot(x, L1, label = "L1")
plot!(x, HL1, label = "Hudson's L1")
xlabel!("Path size")
ylabel!("Average path length")
