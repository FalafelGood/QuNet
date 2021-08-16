using LightGraphs
using QuNet
using LightGraphs
using GraphPlot

# Test remChanVert
net = BasicNetwork()
addNode!(net, 2)
addChannel!(net, 1, 2)
addChannel!(net, 1, 2)
mdg = MetaDiGraph(net)
QuNet.remChanVert(mdg, 4)
