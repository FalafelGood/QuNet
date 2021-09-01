"""
Testset for Routing.jl
"""

using QuNet
using Test

net = BasicNetwork()
addNode!(net, 4)
addChannel!(net, [(1,2),(1,3),(2,4),(3,4)],
[Costs(1.,1.), Costs(1.,1.), Costs(1.,1.), Costs(1.,1.)])
mdg = MetaDiGraph(net)

QuNet.greedyMultiPath!(mdg::MetaDiGraph, [(1,2)])

# @testset "RoutingTests.jl" begin
#
# end
