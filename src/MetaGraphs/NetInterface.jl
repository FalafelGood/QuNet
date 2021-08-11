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
    if n_hasNode(srcid) == false || n_hasNode(dstid) == false
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
    if isdirected == true
        return fwdQuery
    end
    return fwdQuery && n_hasChannel(mdg, dstid, srcid, true)
end


"""
Get a list of channel vertices between two nodes of the network. Return an empty
list if no path is found.
"""
function n_getChannels(mdg::MetaDiGraph, srcid::Int, dstid::Int)
    channels = []
    if n_hasNode(srcid) == false || n_hasNode(dstid) == false
        return []
    end
    # Use cost node if srcid has cost
    src = g_CostVertex(mdg, srcid)
    dst = g_getVertex(mdg, dstid)
    neighbors = common_neighbors(mdg, src, dst)
    for n in neighbors
        if get_prop(mdg, n, :isChannel)
            push!(channels, middle)
        end
    end
    return channels
end


"""
Reduce the channel capacity associated with an channel by one.
If the channel capacity is zero, remove the corresponding edge.
If the channel is undirected, operate on both directions.
"""
function n_remChannel!(mdg::MetaDiGraph, src::Int, dst::Int, chanVert::Int; remHowMany = 1)::Nothing
    if get_prop(mdg, chanVert, :isChannel) == false
        error("Vertex does not correspond to a channel")
    end
    chanSrc = get_prop(mdg, chanVert, :src)
    chanDst = get_prop(mdg, chanVert, :dst)
    @assert(chanSrc in (src, dst) && chanDst in (src, dst))

    isdirected = get_prop(mdg, chanVert, :directed)
    inOrder = (chanSrc == src && chanDst == dst)
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
        # Remove the channel in the proper direction
        if inOrder == true
            rem_edge!(mdg, src, chanVert)
            rem_edge!(mdg, chanVert, dst)
        else
            rem_edge!(mdg, dst, chanVert)
            rem_edge!(mdg, chanVert, src)
        end
    end
    # If chanVert has no adjacent edges, remove chanVert too.
    if degree(mdg, chanVert) == 0
        rem_vertex!(mdg, chanVert)
    end
    return
end


"""
Reduce the channel capacity associated with all channels connecting src and dst
by one. If the channel capacity is zero, remove the channel. If the channel is
undirected, operate on both directions.
"""
function n_remAllChannels!(mdg::MetaDiGraph, src::Int, dst::Int, remHowMany = 1)
    channels = n_getChannels(mdg, src, dst)
    for chan in channels
        n_remChannel!(mdg, src, dst, chan, remHowMany)
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
            candidate == abs(get_prop(mdg, head, :src))
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
edges corresponding to node costs.
"""
function n_removeVertexPath!(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}}; remHowMany = 1)::Nothing
    deadpool = []
    firstLoop == true
    for edge in path
        tail = edge.src
        head = edge.dst
        if firstLoop = true
            if get_prop(mdg, tail, :isChannel) == true
                push!(deadpool, tail)
            end
            firstLoop = false
        end
        if get_prop(mdg, head, :isChannel) == true
            push!(deadpool, head)
        end
    end
    for chanVert in deadpool
        n_remChannel!(mdg, src, dst, chanVert. remHowMany)
    end
    return
end

# """
# Given a path in the MetaDiGraph, convert it to a path in the QNetwork
# """
# function n_path(mdg::MetaDiGraph, path::Vector{Edge{Int}})::Vector{Edge{Int}}
#     qpath = Vector{Edge}()
#     pathLength = length(path)
#     i = 0
#     for edge in path
#         if get_prop(mdg, edge, :isNodeCost) == true
#         else
#             src = edge.src; dst = edge.dst
#             srcid = abs(get_prop(mdg, src, :qid))
#             dstid = abs(get_prop(mdg, dst, :qid))
#             push!(qpath, Edge(srcid, dstid))
#         end
#     end
#     return qpath
# end


# """
# Given a literal path in the MetaGraph, remove it from the network, taking care that
# channel bandwidth is reduced where applicable and making sure not to remove
# edges corresponding to node costs.
# """
# function n_removePath!(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}}; remHowMany = 1)::Nothing
#     deadpool = []
#     for edge in path
#         if typeof(edge) == Vector{Tuple{Int, Int}}; edge = Edge(edge) end
#         if get_prop(mdg, edge, :isNodeCost) == false
#             n_remChannel!(mdg, edge)
#         end
#     end
#     return
# end

"""
Find the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function n_shortestPath(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)
    path, pcosts = g_shortestPath(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)

    if get_prop(mdg, :nodeCosts) == true
        # Filter out edges corresponding to node costs
        path = n_path(mdg, path)
    end
    return path, pcosts
end

"""
Remove the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function n_remShortestPath!(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)
    src = g_index(mdg, src)
    if get_prop(mdg, dst, :hasCost) == true
        dst = g_index(mdg, -dst)
    else
        dst = g_index(mdg, dst)
    end
    @assert Symbol(cost) in fieldnames(Costs)
    cost = addCostPrefix(cost)
    weightfield!(mdg, Symbol(cost))
    path = a_star(mdg, src, dst)
    pcosts = g_pathCosts(mdg, path)
    n_removePath!(mdg, path)
    return path, pcosts
end
