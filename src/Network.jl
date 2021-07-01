"""
Define main structures for Basic and Dynamic QNetworks
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

"""
Add one or more nodes to the network.

If the node being initialised already exists in the network,
(the IDs are equal) addNode replaces it. If node ID is greater
than the number of nodes in the network, function warns user and
sets node ID to nv + 1
"""
function addNode!(net::QNetwork, numNodes::Int)
    # Make and add new nodes to net.list
    curNum = net.numNodes
    newNodes::Array{QNode} = []
    for id in curNum + 1 : curNum + numNodes
        node = BasicNode(id)
        push!(newNodes, node)
    end
    net.nodes = vcat(net.nodes, newNodes)
    net.numNodes += 1
    push!(net.adjList, Vector{Int}())
end

function addNode!(net::QNetwork, node::QNode)
    if node.id <= net.numNodes
        net.nodes[node.id] = node
    elseif node.id == net.numNodes + 1
        push!(net.nodes, node)
        net.numNodes += 1
        push!(net.adjList, Vector{Int}())
    else
        @warn "node.id larger than net.numNodes. Setting node.id = net.numNodes + 1"
        node.id = net.numNodes + 1
        push!(net.nodes, node)
        net.numNodes += 1
        push!(net.adjList, Vector{Int}())
    end
end

function addNode!(net::QNetwork, cost::Costs)
    # set id to net.numNodes + 1
    newNode = BasicNode(net.numNodes + 1, cost)
    addNode!(net, newNode)
end

function addNode!(net::QNetwork, nodeList::Vector{<:QNode})
    for node in nodeList
        addNode!(net, node)
    end
end

function addNode!(net::QNetwork, costList::Vector{Costs})
    for cost in costList
        addNode!(net, cost)
    end
end

"""
Is there a channel between src and dst?
Throws an error if either src or dst are larger than number of nodes in network
"""
function hasChannel(net::QNetwork, src::Int, dst::Int)::Bool
    if src > net.numNodes && dst > net.numNodes
        error("Node(s) does not exist in network")
    end
    if dst in net.adjList[src]
        return true
    end
    return false
end

"""
Fetch the net.channel index of the channel between src and dst
If no channel exists, returns nothing
"""
function getChannelIdx(net::QNetwork, src::Int, dst::Int)
    if src > net.numNodes || dst > net.numNodes
        return nothing
    end
    for (idx, channel) in enumerate(net.channels)
        if (channel.src == src && channel.dst == dst
            || channel.src == dst && channel.dst == src)
            return idx
        end
    end
    return nothing
end

"""
Add one or more channels to the network. Replace the channel if it already
exists. Throws an error if src or dst are not in the network.
"""
function addChannel!(net::QNetwork, src::Int, dst::Int, costs=Costs())::Nothing
    if hasChannel(net, src, dst) == true
        # Find and replace channel
        idx = getChannelIdx(net, src, dst)
        if idx == nothing
            error("Backend failure -- No channel found connecting nodes $src and $dst")
        end
        net.channels[idx] = BasicChannel(src, dst, costs)
    else
        newChannel = BasicChannel(src, dst, costs)
        push!(net.channels, newChannel)
        net.numChannels += 1
        # Update adjacency list
        push!(net.adjList[src], dst)
        push!(net.adjList[dst], src)
        # Don't remove this return.
        return
    end
end

function addChannel!(net::QNetwork, channel::QChannel)::Nothing
    if hasChannel(net, channel.src, channel.dst) == true
        # Find and replace channel
        idx = getChannelIdx(net, channel.src, channel.dst)
        if idx == nothing
            error("Backend failure -- No channel found connecting nodes $src and $dst")
        end
        net.channels[idx] = channel
        return
    else
        push!(net.channels, channel)
        net.numChannels += 1
        # Update adjacency list
        push!(net.adjList[channel.src], channel.dst)
        push!(net.adjList[channel.dst], channel.src)
        # Don't remove this return.
        return
    end
end

function addChannel!(net::QNetwork, channelList::Vector{<:QChannel})
    for channel in channelList
        addChannel!(net, channel)
    end
end

function addChannel!(net::QNetwork, edgeList::Vector{Tuple{Int, Int}})
    for i in 1:length(edgeList)
        src = edgeList[i][1]
        dst = edgeList[i][2]
        newChannel = BasicChannel(src, dst)
        addChannel!(net, newChannel)
    end
end

function addChannel!(net::QNetwork, edgeList::Vector{Tuple{Int, Int}}, costList::Vector{Costs})
    @assert length(edgeList) == length(costList)
    for i in 1:length(edgeList)
        src = edgeList[i][1]
        dst = edgeList[i][2]
        newChannel = BasicChannel(src, dst, costList[i])
        addChannel!(net, newChannel)
    end
end


"""
Master function for converting from QNetwork to more optimised graph types
"""
function convertNet!(net::QNetwork; convertTo::String = "LightGraph")
    conversionMethods = Dict("LightGraph"=>QuNet.toLightGraph)
    @assert convertTo in keys(conversionMethods) "Invalid conversion type. Try ?convertNet! for details."
    return conversionMethods[convertTo](net)
end


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
