"""
TODO:
"""
mutable struct DynamicNetwork <: QNetwork
    nodes::Vector{QNode}
    channels::Vector{QChannel}
    adjList::Vector{Vector{Int}}
    numNodes::Int64
    numChannels::Int64
    nodeUpdate::Function
    channelUpdate::Function

    function BasicNetwork()
        newNet = new([], [], Vector{Vector{Int}}(), 0, 0)
        return newNet
    end

    function BasicNetwork(numNodes::Int)
        newNodes::Array{QNode} = []
        for id in 1:numNodes
            node = BasicNode(id)
            push!(newNodes, node)
        end
        adjList = [Vector{Int}() for i in 1:numNodes]
        newNet = new(newNodes, [], adjList, numNodes, 0)
        return newNet
    end
end
