"""
Interface functions for the MetaDiGraph representation of the QNetwork.
Exported functions have prefix "g_" by convention
"""


"""
Given a QNode, determine whether or not it exists in the MetaDiGraph
"""
function n_hasNode(mdg::MetaDiGraph, nodeid::Int)
    try
        (get_prop(mdg, :nodeToVert))[nodeid]
        return true
    catch err
        return false
    end
end


"""
Given the src and dst of a QChannel, determine if it exists in the MetaDiGraph
"""
function n_hasChannel(mdg::MetaDiGraph, srcid::Int, dstid::Int, directed=false)
    if n_hasNode(mdg, srcid) == false || n_hasNode(mdg, dstid) == false
        return false
    end
    # Use cost node if srcid has cost
    src = g_CostVertex(mdg, srcid)
    dst = g_getVertex(mdg, dstid)
    # Check if there's a node shared between src and dst
    neighbors = common_neighbors(mdg, src, dst)
    if length(neighbors) > 0
        fwdQuery = true
    else
        fwdQuery = false
    end
    if directed == true
        return fwdQuery
    end
    return fwdQuery && n_hasChannel(mdg, dstid, srcid, true)
end

"""
Return the costs for a channel
"""
function n_channelCosts(mdg, srcNode::Int, dstNode::Int, chanVert::Int)
    chancosts = Costs()
    srcVert = g_getVertex(mdg, srcNode)
    dstVert = g_getVertex(mdg, dstNode)
    for costname in fieldnames(Costs)
        formattedName = QuNet.addCostPrefix(string(costname))
        halfVal = get_prop(mdg, srcVert, chanVert, Symbol(formattedName))
        setproperty!(chancosts, costname, 2*halfVal)
    end
    return chancosts
end

"""
Set the costs for a channel
"""
function n_setChannelCosts(mdg, srcNode::Int, dstNode::Int, chanVert::Int, costs::Costs)
    half = halfCost(costs)
    srcVert = g_getVertex(mdg, srcNode)
    dstVert = g_getVertex(mdg, dstNode)
    for costname in fieldnames(Costs)
        formattedName = QuNet.addCostPrefix(string(costname))
        halfVal = getproperty(half, costname)
        set_prop!(mdg, srcVert, chanVert, Symbol(formattedName), halfVal)
        set_prop!(mdg, chanVert, dstVert, Symbol(formattedName), halfVal)
        if get_prop(mdg, chanVert, :directed) == false
            set_prop!(mdg, dstVert, chanVert, Symbol(formattedName), halfVal)
            set_prop!(mdg, chanVert, srcVert, Symbol(formattedName), halfVal)
        end
    end
end

"""
Fetches the channel between srcNode and dstNode provided that one unique channel
exists between them. If not, this function throws an error
"""
function n_uniqueChannel(mdg::MetaDiGraph, srcNode::Int, dstNode::Int)
    channels = n_getChannels(mdg, srcNode, dstNode)
    if length(channels) != 1
        @error("More than one (or 0) channels found in n_uniqueChannel")
    end
    return channels[1]
end

"""
Returns a list of tuples representing a vertex path in the network provided
that each channel is unique. If not, this function throws an error.
"""
function n_uniqueVertexPath(mdg::MetaDiGraph, path::Vector{Tuple{Int, Int}})
    vertPath = []
    for step in path
        srcNode = step[1]
        dstNode = step[2]
        chanVert = n_uniqueChannel(mdg, srcNode, dstNode)
        srcVert = g_getVertex(mdg, srcNode)
        push!(vertPath, srcVert)
        if get_prop(mdg, srcVert, :hasCost) == true
            costVert = g_getVertex(mdg, -srcNode)
            push!(vertPath, costVert)
        end
        push!(vertPath, chanVert)
    end
    lastNode = (last(path))[2]
    lastVert = g_getVertex(mdg, lastNode)
    push!(vertPath, lastVert)
    if get_prop(mdg, lastVert, :hasCost) == true
        costVert = g_getVertex(mdg, -lastNode)
        push!(vertPath, costVert)
    end
    # Convert vertPath to list of tuples
    tuplePath = Vector{Tuple{Int,Int}}()
    for i in 1:length(vertPath)-1
        push!(tuplePath, (vertPath[i], vertPath[i+1]))
    end
    return tuplePath
end

"""
Get a list of channel vertices between two nodes of the network. Return an empty
list if no path is found.
"""
function n_getChannels(mdg::MetaDiGraph, srcNode::Int, dstNode::Int)
    channels = []
    if n_hasNode(mdg, srcNode) == false || n_hasNode(mdg, dstNode) == false
        return []
    end
    # Use cost node if srcNode has cost
    srcVert = g_CostVertex(mdg, srcNode)
    dstVert = g_CostVertex(mdg, dstNode)
    neighbors = common_neighbors(mdg, srcVert, dstVert)
    for n in neighbors
        if get_prop(mdg, n, :isChannel)
            push!(channels, n)
        end
    end
    return channels
end


"""
Reduce the channel capacity associated with an channel by one.
If the channel capacity is zero, remove the corresponding edge.
If the channel is undirected, operate on both directions.
"""
function n_remChannel!(mdg::MetaDiGraph, srcNode::Int, dstNode::Int, chanVert::Int; remHowMany = 1)::Nothing
    if get_prop(mdg, chanVert, :isChannel) == false
        error("chanVert does not correspond to a channel")
    end
    chanSrc = get_prop(mdg, chanVert, :src)
    chanDst = get_prop(mdg, chanVert, :dst)
    @assert(chanSrc in (srcNode, dstNode) && chanDst in (srcNode, dstNode))

    isdirected = get_prop(mdg, chanVert, :directed)
    inOrder = (chanSrc == srcNode && chanDst == dstNode)
    if isdirected == true && inOrder == false
        # No channel to remove
        return
    end

    if inOrder == true
        fieldToModify = :capacity
    else
        fieldToModify = :reverseCapacity
    end

    capacity = get_prop(mdg, chanVert, fieldToModify)
    if capacity > 1
        # Make sure capacity doesn't underflow 0.
        capacity - remHowMany >= 0 ? capacity = capacity - remHowMany : capacity = 0
        set_prop!(mdg, chanVert, fieldToModify, capacity)
    else
        # Remove the channel edges
        srcVert = g_CostVertex(mdg, srcNode)
        dstVert = g_getVertex(mdg, dstNode)
        rem_edge!(mdg, srcVert, chanVert)
        rem_edge!(mdg, chanVert, dstVert)
    end
    # If chanVert has no adjacent edges, remove chanVert too.
    if degree(mdg, chanVert) == 0
        rem_vertex!(mdg, chanVert)
    end
    return
end


"""
Reduce the channel capacity associated with all channels connecting src and dst
by one. If the channel capacity is zero, remove the channel.
"""
function n_remAllChannels!(mdg::MetaDiGraph, src::Int, dst::Int, remHowMany = 1)
    channels = n_getChannels(mdg, src, dst)
    for chan in channels
        n_remChannel!(mdg, src, dst, chan, remHowMany=remHowMany)
    end
end


"""
Add prefix "CostΔ" onto a cost name
"""
function addCostPrefix(cost::String)::String
    cost = "CostsΔ" * cost
    return cost
end

"""
Strip prefix "CostΔ" from cost name
"""
function remCostPrefix(cost::String)::String
    if startswith(cost, "CostsΔ")
        cost = chop(cost, head=length("CostsΔ"), tail=0)
    end
    return cost
end

"""
Given a path in the MetaDiGraph, convert it to a path in the QNetwork
"""
function n_vertexToNetPath(mdg::MetaDiGraph, path::Vector{Edge{Int}})
    qpath = Vector{Edge}()
    pathLength = length(path)
    firstLoop = true
    for edge in path
        tail = edge.src
        head = edge.dst
        if firstLoop == true
            # Check and see if tail is a channel
            if get_prop(mdg, tail, :isChannel) == true
                error("Path begins with a channel vertex and is therefore incomplete")
            end
            firstLoop = false
        end
        if get_prop(mdg, head, :isChannel) == true
            # The channel src is easy to infer since tail must connect to channel vertex
            srcchan = abs(get_prop(mdg, tail, :qid))
            # Two possible values for dstchan, head.src or head.dst
            candidate = abs(get_prop(mdg, head, :src))
            if srcchan == candidate
                dstchan = abs(get_prop(mdg, head, :dst))
            else
                dstchan = candidate
            end
            push!(qpath, Edge(srcchan, dstchan))
        end
    end
    return qpath
end


"""
Given a literal path in the MetaGraph, remove it from the network, taking care that
channel bandwidth is reduced where applicable and making sure not to remove
edges not corresponding to channels.
"""
function n_removeVertexPath!(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}}; remHowMany = 1)::Nothing
    deadpool = []
    # firstLoop == true
    for edge in path
        tail = edge.src
        head = edge.dst
        if get_prop(mdg, head, :isChannel) == true
            # Now that we have the channel vertex, determine the direction
            srcchan = abs(get_prop(mdg, tail, :qid))
            # Two possible values for dstchan, head.src or head.dst
            candidate = abs(get_prop(mdg, head, :src))
            if srcchan == candidate
                dstchan = abs(get_prop(mdg, head, :dst))
            else
                dstchan = candidate
            end
            chanargs = Dict("src"=>srcchan, "dst"=>dstchan, "chanVert"=>head)
            push!(deadpool, chanargs)
        end
    end
    for chanargs in deadpool
        n_remChannel!(mdg, chanargs["src"], chanargs["dst"], chanargs["chanVert"], remHowMany=remHowMany)
    end
    return
end


"""
Find the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function n_shortestPath(mdg::MetaDiGraph, srcNode::Int, dstNode::Int, cost::String)
    srcVert = g_getVertex(mdg, srcNode)
    dstVert = g_CostVertex(mdg, dstNode)
    path, pcosts = g_shortestPath(mdg, srcVert, dstVert, cost)
    path = n_vertexToNetPath(mdg, path)
    return path, pcosts
end


"""
Remove the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function n_remShortestPath!(mdg::MetaDiGraph, srcNode::Int, dstNode::Int, cost::String)
    # TODO
    srcVert = g_getVertex(mdg, srcNode)
    dstVert = g_CostVertex(mdg, dstNode)
    @assert Symbol(cost) in fieldnames(Costs)
    cost = addCostPrefix(cost)
    weightfield!(mdg, Symbol(cost))
    path = a_star(mdg, srcVert, dstVert)
    netPath = n_vertexToNetPath(mdg, path)
    pcosts = g_pathCosts(mdg, path)
    n_removeVertexPath!(mdg, path)
    return netPath, pcosts
end
