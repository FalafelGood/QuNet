"""
Testset for Utilities.jl
"""

using QuNet
using LightGraphs

g = SimpleGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 4)
net = BasicNetwork(g)
convertNet!(net)
ps = Pathset([[(1,2),(2,4)], [(1,3),(3,4)]])
pcosts = QuNet.purifyCosts(net.graph, ps)
QuNet.purify(net, ps)
println(collect(edges(net.graph)))
println(pcosts)
