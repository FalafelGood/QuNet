using QuNet
using Test
using LightGraphs
using MetaGraphs

@testset "NetConversion.jl" begin
    #Test MetaDiGraph with no node costs
    net = BasicNetwork(2)
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net)

    # Check essential graph properties
    @test mdg.gprops[:nodeCosts] == false

    # Check essential node properties
    nodeProps = mdg.vprops[1]
    @test nodeProps[:type] == BasicNode
    @test nodeProps[:qid] == 1
    @test nodeProps[:hasCost] == false

    # Check essential edge properties
    edgeProps = mdg.eprops[Edge(1, 3)]
    @test edgeProps[:isNodeCost] == false

    # Check num edges and vertices agrees
    @test length(mdg.vprops) == 3
    @test length(mdg.eprops) == 4

    # Check graph structure
    edgeList = [Edge(1,3), Edge(3,1), Edge(2,3), Edge(3,2)]
    @test (all(edge in keys(mdg.eprops) for edge in edgeList))

    # Check the costs on a channel edge is half the total value
    # TODO:

    # Test MetaDiGraph with node Costs
    net = BasicNetwork()
    addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0)])
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net, true)

    # Check num edges and vertices agrees
    @test length(mdg.vprops) == 5
    @test length(mdg.eprops) == 6

    # Check graph structure
    edgeList = [Edge(1,2), Edge(3,4), Edge(2,5), Edge(5,1), Edge(5,3), Edge(4,5)]
    @test (all(edge in keys(mdg.eprops) for edge in edgeList))
end

# net = BasicNetwork()
# addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
# addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
# lg = QuNet.toLightGraph(net, true)
#
# result = filter_edges(lg, :isNodeCost, true)
# for edge in result
#     println(edge)
# end

# Test set indexing props for negative index
# lg.metaindex[:qid]
# set_prop!(lg, -1, :dummy, "Hi!")
# props(lg, -1)

# Try shortest path finding
# prop = get_prop(lg, Edge(1,2), :costs)
# weightfield!(lg, :costs.dE)
# a_star(lg, 1, 2)
