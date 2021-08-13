using QuNet
using Test
using StructEquality

@def_structequal Costs
@def_structequal BasicNode
@def_structequal BasicChannel

@testset "Network.jl" begin
    # Test BasicNetwork initialisation
    net = BasicNetwork()
    @test net.nodes == [] && typeof(net.nodes) == Array{QNode, 1}
    @test net.channels == [] && typeof(net.channels) == Array{QChannel, 1}
    @test net.adjList == Vector{Vector{Int}}()
    @test net.numNodes == 0
    @test net.numChannels == 0

    # Test BasicNetwork initialisation with QNodes
    net = BasicNetwork(10)
    @test length(net.nodes) == 10
    @test net.numNodes == 10
    @test all(typeof(n) == BasicNode for n in net.nodes)
    # Check that id is properly initialised
    @test all(n.qid == idx for (idx, n) in enumerate(net.nodes))

    # Test adjacency list init
    @test length(net.adjList) == net.numNodes

    # Test addNode! works on previous network
    addNode!(net, 10)
    @test length(net.nodes) == 20
    @test all(typeof(n) == BasicNode for n in net.nodes)
    # Check that id is still initialised right
    @test all(n.qid == idx for (idx, n) in enumerate(net.nodes))

    # Test addNode replaces existing node in network
    node = BasicNode(5, Costs(1.0, 2.0))
    addNode!(net, node)
    @test (net.nodes[5] == node)

    # Test addNode with id > nv warns the user
    node = BasicNode(100, Costs(1.0, 2.0))
    @test_logs (:warn,) addNode!(net, node)

    # Test addNode! for a cost
    cost = Costs(2.0, 3.0)
    addNode!(net, cost)
    @test (last(net.nodes).costs == cost)

    # Test addNode! for a list of nodes
    net = BasicNetwork()
    node1 = BasicNode(1, Costs(1.0, 2.0))
    node2 = BasicNode(2, Costs(2.0, 3.0))
    addNode!(net, [node1, node2])
    @test(net.nodes[1] == node1 && net.nodes[2] == node2)

    # Test addNode! for a list of Costs
    net = BasicNetwork()
    cost1 = Costs(1.0, 2.0)
    cost2 = Costs(2.0, 3.0)
    addNode!(net, [cost1, cost2])
    @test(net.nodes[1] == node1 && net.nodes[2] == node2)

    # Test addChannel! between nodes one and two
    net = BasicNetwork(3)
    addChannel!(net, 1, 2)
    @test net.channels[1] == BasicChannel(1, 2)

    # Test hasChannel
    @test hasChannel(net, 1, 2) == true

    # Test getChannelIdx
    @test getChannelIdx(net, 1, 2) == 1

    # Test getChannelIdx returns nothing when no edge exists
    @test getChannelIdx(net, 2, 3) == nothing

    # Test getChannelIdx returns nothing when nodes out of range
    @test getChannelIdx(net, 100, 200) == nothing

    # Test getChannel fetches channel
    @test getChannel(net, 1, 2) == BasicChannel(1, 2)

    # Test that adjacency list was updated
    @test 2 in net.adjList[1] && 1 in net.adjList[2]

    # Test addChannel! for preinitialised channel
    channel = BasicChannel(2,3, Costs(1.0, 2.0))
    addChannel!(net, channel)
    @test (net.channels[2] == channel)

    # Test that adjacency list was updated
    @test 3 in net.adjList[2] && 2 in net.adjList[3]

    # Test addChannel! replaces existing channel and doesn't change adjList
    oldAdj = net.adjList
    channel = BasicChannel(2,3, Costs(5.0, 5.0))
    addChannel!(net, channel)
    @test (net.channels[2] == channel)
    newAdj = net.adjList
    @test (oldAdj == newAdj)

    # Test addChannel! throws error when src or dst doesn't exist
    channel = BasicChannel(100, 200)
    @test_throws ErrorException addChannel!(net, channel)

    # Test addChannel for edge
    net = BasicNetwork(3)
    addChannel!(net, QuNet.Edge(1,2))
    @test( length(net.channels) == 1 && net.numChannels == 1)

    # Test addChannel for list of edges
    net = BasicNetwork(3)
    addChannel!(net, [QuNet.Edge(1,2), QuNet.Edge(2,3)])
    @test( length(net.channels) == 2 && net.numChannels == 2)

    # Test addChannel! for list of int tuples
    net = BasicNetwork(3)
    edgeList = [(1,2),(2,3)]
    addChannel!(net, edgeList)
    @test( length(net.channels) == 2 && net.numChannels == 2)
    @test( 2 in net.adjList[3] && 3 in net.adjList[2])
    @test all(channel.directed == false for channel in net.channels)

    # Test addChannel! for list of channels
    net = BasicNetwork(3)
    chan1 = BasicChannel(1,2)
    chan2 = BasicChannel(2,3)
    addChannel!(net, [chan1, chan2])
    @test( length(net.channels) == 2 && net.numChannels == 2)
    @test all(channel.directed == false for channel in net.channels)

    # Test addChannel for list of edges and costs
    net = BasicNetwork(3)
    edgeList = [(1,2), (2,3)]
    costList = [Costs(1.0, 2.0), Costs(2.0, 3.0)]
    addChannel!(net, edgeList, costList)
    @test( net.channels[1] == BasicChannel(1, 2, Costs(1.0, 2.0)))
    @test all(channel.directed == false for channel in net.channels)

end
