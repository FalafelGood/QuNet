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

    # Test BasicNetwork init for SimpleGraph input
    g = SimpleGraph(2)
    add_edge!(g, 1, 2)
    b = BasicNetwork(g)
    @test (b.channels[1] == BasicChannel(1, 2, Costs(1.0, 1.0)))
    @test (length(b.nodes) == b.numNodes)
    @test (length(b.channels) == b.numChannels)
end
