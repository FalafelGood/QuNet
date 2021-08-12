"""
Unit Tests for Interface.jl
"""

using QuNet
using LightGraphs
using MetaGraphs
using Test

@testset "NetInterface.jl" begin
    net = BasicNetwork(3)
    addChannel!(net, 1, 2)
    mdg = MetaDiGraph(net)

    # Test n_hasNode()
    @test QuNet.n_hasNode(mdg, 1) == true
    # Test for node not in the graph
    @test QuNet.n_hasNode(mdg, 100) == false

    # Test n_hasChannel when isdirected == false
    net = BasicNetwork()
    addNode!(net, [Costs(1.,1.), Costs(1.,1.), Costs(1.1, 1.1)])
    addChannel!(net, 1, 2)
    mdg = MetaDiGraph(net)
    @test QuNet.n_hasChannel(mdg, 1, 2) == true
    @test QuNet.n_hasChannel(mdg, 1, 3) == false
    @test QuNet.n_hasChannel(mdg, 1, 34) == false

    # Test n_hasChannel when isdirected == true
    net = BasicNetwork()
    addNode!(net, 2)
    addChannel!(net, 1, 2)
    channel = getChannel(net, 1, 2)
    channel.directed = true
    convertNet!(net)
    @test QuNet.n_hasChannel(net.graph, 2, 1, true) == false

    # Test n_getChannels
    net = BasicNetwork(2)
    addChannel!(net, 1, 2, Costs(1.,1.))
    mdg = MetaDiGraph(net)
    channels = QuNet.n_getChannels(mdg, 1, 2)
    @test 3 in channels

    # Test n_remChannel!
    net = BasicNetwork(2)
    addChannel!(net, 1, 2)
    channel = getChannel(net, 1, 2)
    channel.capacity = 2
    mdg = MetaDiGraph(net)
    n_remChannel!(mdg, 1, 2, 3)
    @test g_getProp(mdg, 3, "capacity") == 1
    n_remChannel!(mdg, 1, 2, 3)
    # Test that directed channel has been removed
    @test has_edge(mdg, 1, 3) == false
    @test has_edge(mdg, 3, 2) == false
    @test has_edge(mdg, 3, 1) == true
    @test has_edge(mdg, 2, 3) == true
    # Remove channel in opposite direction
    n_remChannel!(mdg, 2, 1, 3)
    @test g_getProp(mdg, 3, "reverseCapacity") == 1
    n_remChannel!(mdg, 2, 1, 3)
    # Test that the channel vertex has been removed
    @test (nv(mdg) == 2)

    # Test n_remChannel! for graph with node weights:
    # Make a network with node costs
    net = BasicNetwork()
    addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0)])
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net, true)
    n_remChannel!(mdg, 1, 2, 5)
    @test n_hasChannel(mdg, 1, 2) == false

    # Test addCostPrefix!
    cost = "test"
    newcost = QuNet.addCostPrefix(cost)
    @test(newcost == "CostsΔ" * cost)

    # Test remCostPrefix!
    oldcost = QuNet.remCostPrefix(cost)
    @test(oldcost == cost)

    # Test n_remAllChannels
    net = BasicNetwork(2)
    addChannel!(net, 1, 2)
    channel = getChannel(net, 1, 2)
    channel.capacity = 2
    mdg = MetaDiGraph(net)
    n_remAllChannels!(mdg, 1, 2)
    @test g_getProp(mdg, 3, "capacity") == 1

    # Test n_vertexToNetPath
    # Make a network with node costs
    net = BasicNetwork()
    addNode!(net, [Costs(1.0, 1.0), Costs(1.0, 1.0)])
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net, true)
    netpath = n_vertexToNetPath(mdg, [Edge(1,2), Edge(2,5), Edge(5,3), Edge(3,4)])
    @test netpath == [Edge(1,2)]

    # Test n_removeVertexPath!
    n_removeVertexPath!(mdg, [Edge(1,2), Edge(2,5), Edge(5,3), Edge(3,4)])
    @test n_hasChannel(mdg, 1, 2) == false

    # Test g_edgeCosts for a channel edge (It should be half the cost)
    net = BasicNetwork(2)
    addChannel!(net, 1, 2, Costs(1.0, 2.0))
    convertNet!(net)
    ecosts = g_edgeCosts(net.graph, Edge(1,3))
    @test ecosts == Costs(0.5, 1.0)

    # Test g_edgeCosts errors when edge not found in graph
    @test_throws AssertionError g_edgeCosts(net.graph, Edge(100,200))

    # Test g_pathCosts
    net = BasicNetwork(3)
    addChannel!(net, 1, 2, Costs(1.0, 2.0))
    addChannel!(net, 2, 3, Costs(2.0, 2.0))
    convertNet!(net)
    elist = [Edge(1,4), Edge(4,2), Edge(2,5), Edge(5,3)]::Vector{Edge{Int}}
    pcosts = g_pathCosts(net.graph, elist)
    @test pcosts == Costs(3.0, 4.0)

    # Test g_shortestPath with Node Weights for simple graph
    net = BasicNetwork()
    addNode!(net, Costs(1.0, 1.0))
    addNode!(net, Costs(100.0, 100.0))
    addNode!(net, Costs(2.0, 2.0))
    addChannel!(net, Edge(1,2), Costs(0.0, 0.0))
    addChannel!(net, Edge(1,3), Costs(5.0, 5.0))
    addChannel!(net, Edge(2,3), Costs(0.0, 0.0))
    convertNet!(net, nodeCosts = true)
    path, pcosts = n_shortestPath(net.graph, 1, 3, "dE")
    @test path[1] == Edge(1,3)
    @test pcosts == Costs(8.0, 8.0)

    # Test n_remShortestPath for previous network
    path, pcosts = n_remShortestPath!(net.graph, 1, 3, "dE")
    @test path == [Edge(1,3)]
    path, pcosts = n_remShortestPath!(net.graph, 1, 3, "dE")
    @test path == [Edge(1,2), Edge(2,3)]

    # Test g_shortestPath with Node weights for more complex graph
    net = BasicNetwork()
    costList = repeat([Costs(1.,1.)], 5)
    addNode!(net, costList)
    edgeList = [(1,2),(1,3),(1,4),(2,5),(3,5),(4,5)]
    costList = [Costs(1.,1.), Costs(2.,2.), Costs(3., 3.),
                Costs(1.,1.), Costs(2.,2.), Costs(3., 3.)]
    addChannel!(net, edgeList, costList)
    convertNet!(net, nodeCosts = true)
    path, pcosts = n_shortestPath(net.graph, 1, 5, "dF")
    @test path == [Edge(1,2), Edge(2,5)]
    @test pcosts == Costs(5., 5.)

    # Test n_remShortestPath! for more complex graph
    n_remShortestPath!(net.graph, 1, 5, "dF")
    @test QuNet.n_hasChannel(net.graph, 1, 2) == false && QuNet.n_hasChannel(net.graph, 2, 5) == false

    # Test g_shortestPath! for channels where :active == false
    net = BasicNetwork(2)
    addChannel!(net, 1, 2, Costs(1.0, 1.0))
    channel = getChannel(net, 1, 2)
    channel.active = false
    mdg = MetaDiGraph(net)
    path, costs = g_shortestPath(mdg, 1, 2, "dE")
    # Check that no path is found
    @test path == [] && costs == Costs()

    # # Test property was correctly reset
    # @test get_prop(net.graph, 1, 2, :CostsΔdE) == 1.0
    #
    # """
    # Make a partially disabled network to test filtering for inactive
    # edges and inactive vertices
    # """
    # function makeDisabledNetwork()
    #     net = BasicNetwork(5)
    #     addChannel!(net, [(1,2),(2,3),(3,1)])
    #     addChannel!(net, [(1,4),(4,5)])
    #
    #     for srcdst in [(1,2),(2,3),(3,1)]
    #         channel = getChannel(net, srcdst[1], srcdst[2])
    #         channel.active = false
    #     end
    #
    #     node = net.nodes[4]
    #     node.active = false
    #
    #     convertNet!(net)
    #     return net
    # end
    #
    # net = makeDisabledNetwork()
    # filteredNet = g_filterInactiveEdges(net.graph)
    # deletedEdges = [Edge(1,2), Edge(2,3), Edge(3,1),
    #                 Edge(2,1), Edge(3,2), Edge(1,3)]
    # remainingEdges = [Edge(1,4), Edge(4,5), Edge(4,1), Edge(5,4)]
    # @test all(has_edge(filteredNet, edge) == false for edge in deletedEdges)
    # @test all(has_edge(filteredNet, edge) == true for edge in remainingEdges)
    #
    # filteredNet = g_filterInactiveVertices(net.graph)
    # deletedEdges = [Edge(1,4), Edge(4,5), Edge(4,1), Edge(5,4)]
    # remainingEdges = [Edge(1,2), Edge(2,3), Edge(3,1),
    #                 Edge(2,1), Edge(3,2), Edge(1,3)]
    # @test all(has_edge(filteredNet, edge) == false for edge in deletedEdges)
    # @test all(has_edge(filteredNet, edge) == true for edge in remainingEdges)
end
