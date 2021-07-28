"""
TODO: Not yet working
"""

mutable struct DynamicNetwork <: QNetwork
    nodes::Vector{QNode}
    channels::Vector{QChannel}
    adjList::Vector{Vector{Int}}
    numNodes::Int64
    numChannels::Int64
    nodeUpdate::Function
    channelUpdate::Function
    graph::String

    function DynamicNetwork()
        newNet = new([], [], Vector{Vector{Int}}(), 0, 0)
        return newNet
    end

    function DynamicNetwork(numNodes::Int)
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

"""
Simulate the network over a period of time
"""
function simulate!(net::DynamicNetwork, dt::Float64, tMax::Float64)
    graphType::Type = MetaDiGraph, fileName::String = "mysim")

    # TODO Is this necessary?
    convMethods = Dict(graphType=>QuNet.toLightGraph)
    @assert convertTo in keys(convMethods) "Invalid conversion type. Try ?convertNet! for details."

    graph = convMethods[convertTo](net))
    # Initialise graph by setting dt = 0.0
    g1 = update!(graph, 0.0)
    filePath = "/Simulations" * fileName * ".mg"
    @save filePath g1
    g1 = nothing
    times = collect(start+dt:dt:tMax)
    for (idx, time) in enumerate(times)
        # Make ith graph g_i, save it, then remove it from workspace
        @eval $(Symbol(:g, idx)) = updateGraph!(graph, dt)
        @save filePath @eval $(Symbol(:g, time))
        @eval $(Symbol(:g, idx)) = nothing
    end
end

function updateGraph!(graph, dt::Float64)

end
