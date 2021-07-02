using QuNet
using Test
using LightGraphs
using MetaGraphs

# @testset "Conversions.jl" begin
#     #Test toLightGraph with standard network
#     net = BasicNetwork(3)
#     addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
#     lg = QuNet.toLightGraph(net)
#
#     # Check num edges and vertices agrees
#     @test length(lg.vprops) == 3
#     @test length(lg.eprops) == 6
#
#     # Check structure
#     edgeList = [Edge(1,2), Edge(2,3), Edge(3,1),
#                 Edge(2,1), Edge(3,2), Edge(1,3)]
#     @test (all(edge in keys(lg.eprops) for edge in edgeList))
#
#     # Check properties of an edge
#     edge = lg.eprops[Edge(1, 3)]
#     # TODO: Figure out this test...
#     # @test edge[:src] == 1
#     # @test edge[:dst] == 3
#     @test edge[:CostsΔdE] == 1.0
#     @test edge[:CostsΔdF] == 1.0
#     @test edge[:active] == true
#     # TODO -- Better tests here
#
#     # Test toLightGraph when nodes have costs
# end

net = BasicNetwork()
addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
lg = QuNet.toLightGraph(net, true)


# prop = get_prop(lg, Edge(1,2), :costs)
# weightfield!(lg, :costs.dE)
# a_star(lg, 1, 2)

# Test set indexing props for negative index
# lg = MetaGraph(3)
# add_edge!(lg, 1, 2)
# set_prop!(lg, 1, :id, -1)
# set_prop!(lg, 2, :id, -2)
# set_prop!(lg, 3, :id, 3)
# myprop = get_prop(lg, 1, :id)
# set_indexing_prop!(lg, :id)
# lg[1, :id]
# lg[-1, :id]
# lg.metaindex[:id][-1]
# set_prop!(lg, -1, :dummy, "Hi!")
# props(lg, -1)
