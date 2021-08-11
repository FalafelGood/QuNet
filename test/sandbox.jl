using LightGraphs
using QuNet

# Make a network with node costs
net = BasicNetwork()
addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0)])
addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
mdg = MetaDiGraph(net, true)

# Test mapNodeToVert!
tmp = (get_prop(mdg, :nodeToVert))[1]
QuNet.mapNodeToVert!(mdg, 1, 100)
@test (get_prop(mdg, :nodeToVert))[1] == 100
QuNet.mapNodeToVert!(mdg, 1, tmp)

# Test g_getNode
nodeid = QuNet.g_getNode(mdg, 1)
@test nodeid == 1

# println(nv(mdg))
# println(ne(mdg))
# println(mdg.gprops)
