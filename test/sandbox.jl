using LightGraphs
using QuNet
using LightGraphs
using GraphPlot

g = SimpleGraph(4)
add_edge!(g, 1, 2)
add_edge!(g, 1, 3)
add_edge!(g, 2, 4)
add_edge!(g, 3, 4)
net = BasicNetwork(g)
mdg = MetaDiGraph(net)
c12 = n_uniqueChannel(mdg, 1, 2)
c13 = n_uniqueChannel(mdg, 1, 3)
c24 = n_uniqueChannel(mdg, 2, 4)
c34 = n_uniqueChannel(mdg, 3, 4)
ps = Pathset([[(1,c12),(c12, 2),(2,c24),(c24,4)], [(1,c13),(c13,3),(3, c34),(c34,4)]])
path1 = QuNet.n_uniqueVertexPath(mdg, [(1,2),(2,4)])
path2 = QuNet.n_uniqueVertexPath(mdg, [(1,3),(3,4)])
ps2 = Pathset([path1, path2])
println(path1)
println(path2)

# pcosts = QuNet.purifyCosts(mdg, ps)
# QuNet.purify(mdg, ps)
# println(collect(edges(net.graph)))
# println(pcosts)
