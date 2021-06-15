"""
This script finds the probability that a new user
pair will find a path in a grid lattice with
a number of other competing end-users.
"""

using LightGraphs
using QuNet
using Statistics
using Plots

# Make grid network
# Get a list of random users
# For each user
    # Find the shortest path between them
        # If it exists, remove it, add a success to the user tally
        # If it doesn't, add a failure to the user tally
# Repeat for another set of end-users

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

NO_PATH_FOUND = 0
PATH_FOUND = 1

# Params
numPairs = 50
numSamples = 50000
dimX = 10; dimY = 10
makeNewData = true

# MAIN
if makeNewData == false
    pathStats = [[] for i in collect(1:numPairs)]

    for sample in 1:numSamples
        g = LightGraphs.grid([dimX, dimY])
        userPairs = make_userpairs(nv(g), numPairs)
        for (pairidx, pair) in enumerate(userPairs)
            shortestPath = a_star(g, pair[1], pair[2])
            if length(shortestPath) == 0
                push!(pathStats[pairidx], NO_PATH_FOUND)
            else
                push!(pathStats[pairidx], PATH_FOUND)
            end
            for edge in shortestPath
                rem_edge!(g, edge)
            end
        end
    end

    pathProbs = []

    for pairNumData in pathStats
        pathRate = mean(pairNumData)
        push!(pathProbs, pathRate)
    end
end

x = collect(1:numPairs)
plot(x, pathProbs)
title!("Probability nth user finds path in 10 x 10 grid")
xlabel!("Pair number")
ylabel!("Probability of finding path")
