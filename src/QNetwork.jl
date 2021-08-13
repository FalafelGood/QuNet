"""
Main API manipulating QNetwork objects such as BasicNetworks or DynamicNetworks
"""

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
        net.numNodes += 1
    end
    net.nodes = vcat(net.nodes, newNodes)
end

function addNode!(net::QNetwork, node::QNode)
    if node.qid <= net.numNodes
        net.nodes[node.qid] = node
    elseif node.qid == net.numNodes + 1
        push!(net.nodes, node)
        net.numNodes += 1
    else
        @warn "node.id larger than net.numNodes. Setting node.id = net.numNodes + 1"
        node.qid = net.numNodes + 1
        push!(net.nodes, node)
        net.numNodes += 1
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
Get the node corresponding to the given id. If no node exists, returns nothing
"""
function getNode(net::QNetwork, id::Int)
    if id > net.numNodes
        return nothing
    end
    return net.nodes[id]
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
Get the channel between src and dst. If no channel exists, return nothing
"""
function getChannel(net::QNetwork, src::Int, dst::Int)
    idx = getChannelIdx(net, src, dst)
    if idx == nothing; return nothing; end
    return net.channels[idx]
end

"""
Add one or more channels to the network.

# TODO: Throw an error if src or dst not in the network
"""
function addChannel!(net::QNetwork, src::Int, dst::Int, costs=Costs())::Nothing
    if src > net.numNodes || dst > net.numNodes
        error("Src or dst not in the network")
    end
    newChannel = BasicChannel(src, dst, costs)
    push!(net.channels, newChannel)
    net.numChannels += 1
    return
end

function addChannel!(net::QNetwork, edge::AbstractEdge, costs=Costs())::Nothing
    src = edge.src; dst = edge.dst
    addChannel!(net, src, dst, costs)
    return
end

function addChannel!(net::QNetwork, channel::QChannel)::Nothing
    if channel.src > net.numNodes || channel.dst > net.numNodes
        error("Src or dst not in the network")
    end
    push!(net.channels, channel)
    net.numChannels += 1
    # Don't remove this return.
    return
end

function addChannel!(net::QNetwork, channelList::Vector{<:QChannel})
    for channel in channelList
        addChannel!(net, channel)
    end
end

function addChannel!(net::QNetwork, edgeList::Vector{<:AbstractEdge})
    for edge in edgeList
        addChannel!(net, edge)
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
Get the costs of a path in the network.
"""
function pathCosts(net::QNetwork, path::Vector{Tuple{Int, Int}})
    pcosts = Costs()
    for costType in fieldnames(Costs)
        for edge in path
            src = getNode(net, path[1]); dst = getNode(net, path[2])
            oldCosts = getproperty(pcosts, costType)
            nodeCosts = getproperty(src.costs, costType)
            channelCosts = getproperty(channel.costs, costType)
            setproperty!(pcosts, costType, oldCosts + nodeCosts + channelCosts)
        end
        # Don't forget last node
        lastNode = getNode(net, last(path)[2])
        lastNodeCosts = getproperty(lastNode.costs, costType)
        oldCosts = getproperty(pcosts, costType)
        setproperty!(pcosts, costType, oldCosts + lastNodeCosts)
    end
    return pcosts
end
