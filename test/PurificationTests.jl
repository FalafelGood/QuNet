"""
Testset for Utilities.jl
"""

using QuNet
using LightGraphs

net = BasicNetwork()
addNode!(net, [Costs(1.,1.), Costs(1.,1.), Costs(1.,1.), Costs(1.,1.)])
addChannel!(net, [(1,2),(1,3),(2,4),(3,4)])
mdg = MetaDiGraph(net, true)

# QuNet.plotNetworkGraph(mdg)

path1 = QuNet.n_uniqueVertexPath(mdg, [(1,2),(2,4)])
path2 = QuNet.n_uniqueVertexPath(mdg, [(1,3),(3,4)])

ps = Pathset([path1, path2])
QuNet.purify(mdg, ps, addChannel = false, bidirectional=false)
QuNet.plotNetworkGraph(mdg)
