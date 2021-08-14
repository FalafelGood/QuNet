using QuNet
using MetaGraphs
using Test

@testset "GraphInterfaceTests" begin

    # Make a network with node costs
    net = BasicNetwork()
    addNode!(net, 2)
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net)

    # Test mapNodeToVert!
    tmp = (get_prop(mdg, :nodeToVert))[1]
    QuNet.mapNodeToVert!(mdg, 1, 100)
    @test (get_prop(mdg, :nodeToVert))[1] == 100
    QuNet.mapNodeToVert!(mdg, 1, tmp)

    # Test g_getNode
    @test QuNet.g_getNode(mdg, 1) == 1
    @test QuNet.g_getNode(mdg, 2) == 2
    # Test g_getNode for node that doesn't exist
    @test QuNet.g_getNode(mdg, 100) == 0

    # Test g_getVertex
    v = QuNet.g_getVertex(mdg, 1)
    @test v == 1
    # Test for Node that doesn't exist in network
    @test QuNet.g_getVertex(mdg, 100) == false

    # Test g_addVertex!
    testgraph = MetaGraph()
    v = QuNet.g_addVertex!(testgraph)
    # Check the vertex has one of the properties from the global vertexProps dict.
    @test (has_prop(testgraph, v, :isChannel))

    # Test g_addEdge!
    testgraph = MetaGraph(2)
    QuNet.g_addEdge!(testgraph, 1, 2)
    # Check edge has one of properties from global edgeProps dict
    @test (has_prop(testgraph, 1, 2, :isChannel))

    # Test g_hasEdge
    @test QuNet.g_hasEdge(testgraph, 1, 2) == true

    # Test g_remEdge!
    QuNet.g_remEdge!(testgraph, (1, 2))
    @test QuNet.g_hasEdge(testgraph, 1, 2) == false

    # Test g_getProp
    @test QuNet.g_getProp(mdg, "nodeToVert") != nothing

    # Test g_edgeCosts
    @test QuNet.g_edgeCosts(mdg, (3,1)) == Costs(.5,.5)

    # Test g_pathCosts
    net = BasicNetwork()
    addNode!(net, 2)
    addChannel!(net, [(1,2)], [Costs(1.0, 1.0)])
    mdg = MetaDiGraph(net)
    @test QuNet.g_pathCosts(mdg, [(1,3),(3,2)]) == Costs(1.,1.)

    # Test g_shortestPath
    # TODO: Rewrite g_filterInactiveChannels
    # TODO: Rewrite g_filterInactiveVertices
    # Test g_filterInactiveVertices
end
