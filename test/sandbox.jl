using LightGraphs
using QuNet
using LightGraphs
using GraphPlot

# Test g_shortestPath! for channels where :active == false
net = BasicNetwork(2)
addChannel!(net, 1, 2, Costs(1.0, 1.0))
channel = getChannel(net, 1, 2)
channel.active = false
mdg = MetaDiGraph(net)
path, costs = g_shortestPath(mdg, 1, 2, "dE")
println(path)
println(costs)
# TODO: Check that no path is found
