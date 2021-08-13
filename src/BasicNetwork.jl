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
    numNodes::Int64
    numChannels::Int64

    function BasicNetwork()
        newNet = new([], [], 0, 0)
        return newNet
    end

    function BasicNetwork(numNodes::Int)
        newNodes::Array{QNode} = []
        for id in 1:numNodes
            node = BasicNode(id)
            push!(newNodes, node)
        end
        newNet = new(newNodes, [], numNodes, 0)
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
    return newNet
end
