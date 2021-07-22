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

#
# """
# Master function for converting from QNetwork to more optimised graph types
# """
# function convertNet!(net::QNetwork; graphType::Type = MetaDiGraph, nodeCosts = false)
#     convMethods = Dict(MetaDiGraph=>QuNet.toLightGraph)
#     @assert graphType in keys(convMethods) "Invalid conversion type. Try ?convertNet! for details."
#     net.graph = convMethods[graphType](net, nodeCosts)
# end


# """
# refresh_graph!(network::QNetwork)
#
# Converts a QNetwork into several weighted LightGraphs (one
# graph for each associated cost), then updates the QNetwork.graph attribute
# with these new graphs.
# """
# function refresh_graph!(network::QNetwork)
#
#     refreshed_graphs = Dict{String, SimpleWeightedDiGraph}()
#
#     for cost_key in keys(zero_costvector())
#         refreshed_graphs[cost_key] = SimpleWeightedDiGraph()
#
#         # Vertices
#         add_vertices!(refreshed_graphs[cost_key], length(network.nodes))
#
#         # Channels
#         for channel in network.channels
#             if channel.active == true
#                 src = findfirst(x -> x == channel.src, network.nodes)
#                 dest = findfirst(x -> x == channel.dest, network.nodes)
#                 weight = channel.costs[cost_key]
#                 add_edge!(refreshed_graphs[cost_key], src, dest, weight)
#                 add_edge!(refreshed_graphs[cost_key], dest, src, weight)
#             end
#         end
#     end
#     network.graph = refreshed_graphs
# end
#
# """
# ```function update(network::QNetwork, new_time::Float64)```
#
# The `update` function iterates through all objects in the network and updates
# them according to a new global time.
# """
# function update(network::QNetwork, new_time::Float64)
#     old_time = network.time
#     for node in network.nodes
#         update(node, old_time, new_time)
#     end
#
#     for channel in network.channels
#         update(channel, old_time, new_time)
#     end
#     network.time = new_time
# end
#
# """
# ```function update(network::QNetwork)```
#
# This instance of update iterates through all objects in the network and updates
# them by the global time increment TIME_STEP defined in QuNet.jl
# """
# function update(network::QNetwork)
#     old_time = network.time
#     new_time = old_time + TIME_STEP
#     for node in network.nodes
#         update(node, old_time, new_time)
#     end
#
#     for channel in network.channels
#         update(channel, old_time, new_time)
#     end
#     network.time = new_time
# end


# """
#     getnode(network::QNetwork, id::Int64)
#
# Fetch the node object corresponding to the given ID / Name
# """
# function getnode(network::QNetwork, id::Int64)
#     return network.nodes[id]
# end
#
#
# function getnode(network::QNetwork, name::String)
#     for node in network.nodes
#         if node.name == name
#             return node
#         end
#     end
# end
#
# function getchannel(network::QNetwork, src::Union{Int64, String},
#     dst::Union{Int64, String})
#     src = getnode(network, src)
#     dst = getnode(network, dst)
#     for channel in network.channels
#         if channel.src == src && channel.dest == dst
#             return channel
#         end
#     end
# end
