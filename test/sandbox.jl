using LightGraphs
using QuNet
using LightGraphs
using GraphPlot

# Test n_hasChannel when isdirected == true
net = BasicNetwork()
addNode!(net, 2)
addChannel!(net, 1, 2)
channel = getChannel(net, 1, 2)
channel.directed = true
mdg = MetaDiGraph(net)
@test QuNet.n_hasChannel(mdg, 2, 1, true) == false

# Test n_channelCosts
chan = n_uniqueChannel(mdg, 1, 2)
result = (n_channelCosts(mdg, 1, 2, chan) == Costs(0.,0.))
println(result)
