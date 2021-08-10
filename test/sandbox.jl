using LightGraphs
using QuNet

net = BasicNetwork(3)
addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
lg = MetaDiGraph(net)
println(nv(lg))

for edge in edges(lg)
    println(edge)
end

println(lg.eprops)
