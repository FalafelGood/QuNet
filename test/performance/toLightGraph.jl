"""
Benchmark speed for converting a large QuNet into a LightGraph

nv == ne ==: 10^k
k=1 0.000284 seconds (2.07 k allocations: 228.594 KiB)
k=2 0.002254 seconds (20.17 k allocations: 2.206 MiB)
k=3 0.024331 seconds (209.78 k allocations: 21.994 MiB)
k=4 0.215780 seconds (2.15 M allocations: 220.057 MiB)
k=5 3.670594 seconds (21.69 M allocations: 2.157 GiB, 45.87% gc time)
k=6 65.512922 seconds (220.38 M allocations: 21.605 GiB, 65.86% gc time)
"""

using QuNet
using LightGraphs
using MetaGraphs

nv = 10^4
ne = 10^4
net = BasicNetwork(N)

# Generate some random edges:
randomGraph = erdos_renyi(nv, ne)
randomEdges= collect(edges(randomGraph))#::Vector{<:AbstractEdge}

# Make QNetwork
net = BasicNetwork(nv)
addChannel!(net, randomEdges)

# Convert QNetwork to LightGraph
@time graph = QuNet.toLightGraph(net)
