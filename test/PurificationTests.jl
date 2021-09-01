"""
Testset for Purifications.jl
"""

using QuNet
using LightGraphs

net = BasicNetwork()
addNode!(net, 4)
addChannel!(net, [(1,2),(1,3),(2,4),(3,4)])
mdg = MetaDiGraph(net)

# QuNet.plotNetworkGraph(mdg)

# QuNet.plotNetworkGraph(mdg)
path1 = QuNet.n_uniqueVertexPath(mdg, [(1,2),(2,4)])
path2 = QuNet.n_uniqueVertexPath(mdg, [(1,3),(3,4)])

ps = Pathset([path1, path2])
QuNet.purify(mdg, ps, addChannel = true)
QuNet.plotNetworkGraph(mdg)
#
# # Go in reverse
# # rps = QuNet.reversePathset(ps)
# # QuNet.purify(mdg, rps, addChannel = true, bidirectional=false)
# # ntv = get_prop(mdg, :nodeToVert)
#
# QuNet.plotNetworkGraph(mdg)
