using QuNet
using Test
using LightGraphs
using MetaGraphs

@testset "NetConversion.jl" begin
    #Test MetaDiGraph
    net = BasicNetwork(2)
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net)

    # Check essential node properties
    nodeProps = mdg.vprops[1]
    @test nodeProps[:type] == BasicNode
    @test nodeProps[:qid] == 1

    # Check that all vertices have :isChannel property
    @test all(has_prop(mdg, v, :isChannel) for v in vertices(mdg))

    # Check num edges and vertices agrees
    @test length(mdg.vprops) == 3
    @test length(mdg.eprops) == 4

    # Check graph structure
    edgeList = [Edge(1,3), Edge(3,1), Edge(2,3), Edge(3,2)]
    @test (all(edge in keys(mdg.eprops) for edge in edgeList))

    # Check the costs on a channel edge is half the total value
    # TODO:
end
