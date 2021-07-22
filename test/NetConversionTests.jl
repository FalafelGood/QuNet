using QuNet
using Test
using LightGraphs
using MetaGraphs

@testset "NetConversion.jl" begin
    #Test toLightGraph with no node costs
    net = BasicNetwork(3)
    addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
    lg = MetaDiGraph(net)

    # Check essential graph properties
    @test lg.gprops[:nodeCosts] == false

    # Check num edges and vertices agrees
    @test length(lg.vprops) == 3
    @test length(lg.eprops) == 6

    # Check graph structure
    edgeList = [Edge(1,2), Edge(2,3), Edge(3,1),
                Edge(2,1), Edge(3,2), Edge(1,3)]
    @test (all(edge in keys(lg.eprops) for edge in edgeList))

    # Check essential node properties
    nodeProps = lg.vprops[1]
    @test nodeProps[:type] == BasicNode
    @test nodeProps[:id] == 1
    @test nodeProps[:hasCost] == false

    # Check essential edge properties
    edgeProps = lg.eprops[Edge(1, 3)]
    @test edgeProps[:type] == BasicChannel
    @test edgeProps[:src] == 1
    @test edgeProps[:dst] == 3
    @test edgeProps[:isNodeCost] == false

    # Test toLightGraph when nodes have costs
    net = BasicNetwork()
    addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
    addChannel!(net, [(1,2),(2,3),(3,1)], [Costs(1.0, 1.0), Costs(1.0, 1.0), Costs(1.0, 1.0)])
    lg = MetaDiGraph(net, true)

    # Check essential graph properties
    @test lg.gprops[:nodeCosts] == true

    # Check num edges and vertices agrees
    @test length(lg.vprops) == 6 # numVertices = numNodes + numNodes with cost
    @test length(lg.eprops) == 9 # numEdges = numChannels + numNodes with cost

    # Check edges for node costs properly initialised
    # These are edges where :isNodeCost == true and :src == -:dst
    edge_itr = filter_edges(lg, :isNodeCost, true)
    @test all(get_prop(lg, edge, :src) == -get_prop(lg, edge, :dst) for edge in edge_itr)

    # Check graph structure, ignoring node cost edges
    edge_itr = filter_edges(lg, :isNodeCost, false)
    edgeList = [Edge(-1,2), Edge(-2,3), Edge(-3,1),
                Edge(-2,1), Edge(-3,2), Edge(-1,3)]
    @test all(
    Edge(get_prop(lg, edge, :src), get_prop(lg, edge, :dst))
    in edgeList for edge in edge_itr
    )
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
# lg.metaindex[:id]
# set_prop!(lg, -1, :dummy, "Hi!")
# props(lg, -1)

# Try shortest path finding
# prop = get_prop(lg, Edge(1,2), :costs)
# weightfield!(lg, :costs.dE)
# a_star(lg, 1, 2)
