"""
Unit Tests for Interface.jl
"""

using QuNet
using LightGraphs
using MetaGraphs
using Test

@testset "Interface.jl" begin
    """
    Make a partially disabled network to test filtering for inactive
    edges and inactive vertices
    """
    function makeDisabledNetwork()
        net = BasicNetwork(5)
        addChannel!(net, [(1,2),(2,3),(3,1)])
        addChannel!(net, [(1,4),(4,5)])

        for srcdst in [(1,2),(2,3),(3,1)]
            channel = getChannel(net, srcdst[1], srcdst[2])
            channel.active = false
        end

        node = net.nodes[4]
        node.active = false

        convertNet!(net)
        return net
    end

    net = makeDisabledNetwork()
    filteredNet = filterInactiveEdges(net.graph)
    deletedEdges = [Edge(1,2), Edge(2,3), Edge(3,1),
                    Edge(2,1), Edge(3,2), Edge(1,3)]
    remainingEdges = [Edge(1,4), Edge(4,5), Edge(4,1), Edge(5,4)]
    @test all(has_edge(filteredNet, edge) == false for edge in deletedEdges)
    @test all(has_edge(filteredNet, edge) == true for edge in remainingEdges)

    filteredNet = filterInactiveVertices(net.graph)
    deletedEdges = [Edge(1,4), Edge(4,5), Edge(4,1), Edge(5,4)]
    remainingEdges = [Edge(1,2), Edge(2,3), Edge(3,1),
                    Edge(2,1), Edge(3,2), Edge(1,3)]
    @test all(has_edge(filteredNet, edge) == false for edge in deletedEdges)
    @test all(has_edge(filteredNet, edge) == true for edge in remainingEdges)
end
