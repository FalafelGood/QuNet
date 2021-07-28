"""
Define main structure for Basic QNetwork
"""

"""
Basic QNetwork structure. Although it is mutable, removing nodes and
channels should be avoided. Large manipulations are done by parsing QuNet
into more optimised graph structures via convertNet!()
"""
mutable struct BasicNetwork <: QNetwork
    nodes::Vector{QNode}
    channels::Vector{QChannel}
    adjList::Vector{Vector{Int}}
    numNodes::Int64
    numChannels::Int64
    graph

    function BasicNetwork()
        newNet = new([], [], Vector{Vector{Int}}(), 0, 0, nothing)
        return newNet
    end

    function BasicNetwork(numNodes::Int)
        newNodes::Array{QNode} = []
        for id in 1:numNodes
            node = BasicNode(id)
            push!(newNodes, node)
        end
        adjList = [Vector{Int}() for i in 1:numNodes]
        newNet = new(newNodes, [], adjList, numNodes, 0, nothing)
        return newNet
    end
end

function BasicNetwork(g::SimpleGraph{T}, edgeCosts::Costs = Costs(1.0, 1.0)) where T<:Integer
    newNet = BasicNetwork()
    newNet.numNodes = nv(g)
    newNet.numChannels = ne(g)
    newNet.nodes = []
    newNet.channels = []

    for id in 1:newNet.numNodes
        node = BasicNode(id)
        push!(newNet.nodes, node)
    end
    for edge in edges(g)
        channel = BasicChannel(edge.src, edge.dst, edgeCosts)
        push!(newNet.channels, channel)
    end
    newNet.adjList = g.fadjlist
    return newNet
end
