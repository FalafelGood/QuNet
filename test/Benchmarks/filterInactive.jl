"""
Benchmarking speed for filterInactiveEdges and filterInactiveNodes

Testing shows that filterInactiveEdges is a bit faster than the remove method
I would have written normally. (At the cost of around twice as many
allocations... Progress?)

Filter Inactive nodes on the other hand is much more performant. It's a nice
trick filtering out neighboring edges instead.
"""

using QuNet
using LightGraphs
using MetaGraphs
using Random

nv = 10^5
ne = 10^5

# Generate some random edges:
randomGraph = erdos_renyi(nv, ne)
randomEdges= collect(edges(randomGraph))#::Vector{<:AbstractEdge}

# Make QNetwork
net = BasicNetwork(nv)
addChannel!(net, randomEdges)

# Introduce edge percolations
for channel in net.channels
    if rand(1)[1] > 0.5
        channel.active = false
    end
end

# Introduce node percolations
for node in net.nodes
    if rand(1)[1] > 0.5
        node.active = false
    end
end

# Convert QNetwork to LightGraph
mdg = QuNet.toLightGraph(net)

# make new filtered graph
println(" ")
println("Timing filterInactiveEdges")
@time filterInactiveEdges(mdg)

# Compare with removing edges with for loop
function normalEdgeRemove(mdg)
    kill_list = []
    for edge in edges(mdg)
        if get_prop(mdg, edge, :active) == false
            push!(kill_list, edge)
        end
    end
    for edge in kill_list
        rem_edge!(mdg, edge)
    end
end

graphCopy = deepcopy(mdg)
println("Timing normalRemove")
@time normalEdgeRemove(mdg)

# Try removing nodes
println("Timing filterInactiveVertices")
@time filterInactiveVertices(mdg)

function normalNodeRemove(mdg)
    kill_list = []
    for node in vertices(mdg)
        if get_prop(mdg, node, :active) == false
            push!(kill_list, node)
        end
    end
    for node in kill_list
        rem_vertex!(mdg, node)
    end
end

graphCopy = deepcopy(mdg)
println("Timing normalNodeRemove")
@time normalNodeRemove(mdg)
