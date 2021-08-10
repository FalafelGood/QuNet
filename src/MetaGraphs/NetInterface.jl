"""
Interface functions for the MetaDiGraph representation of the QNetwork.
Exported functions have prefix "g_" by convention
"""

#TODO
# function g_addChannel(mdg::MetaDiGraph, src::Int, dst::Int; isdirected = false)
#     if add_edge!(mdg, src, dst) == false
#         @error("$src or $dst not valid nodes in the graph")
#     end
#     if isdirected == false
#         add_edge!(mdg, dst, src)
#     end
# end

"""
Get the :qid of a network node from the index of a graph vertex
"""
function n_index(mdg::MetaDiGraph, netidx)
    return mdg[netidx, :qid]
end

"""
Return true if a channel exists between the two nodes in the network,
and false otherwise. If isdirected = false, this function returns true only if
the channel is undirected.
"""
function n_hasChannel(mdg::MetaDiGraph, src::Int, dst::Int, isdirected = false)
    if src > nv(mdg) || dst > nv(mdg)
        return false
    end
    if get_prop(mdg, src, :hasCost) == true
        src = -src
    end
    src = g_index(mdg, src)
    dst = g_index(mdg, dst)
    fwdQuery = has_edge(mdg, src, dst)
    if isdirected == true
        return fwdQuery
    end
    return fwdQuery && has_edge(mdg, dst, src)
end

"""
Reduce the channel capacity associated with an channel by one.
If the channel capacity is zero, remove the corresponding edge.
If the channel is undirected, operate on both directions.
"""
function n_remChannel!(mdg::MetaDiGraph, edge::Edge; remHowMany = 1)::Nothing
    if get_prop(mdg, edge, :isNodeCost) == true
        @warn ("edge in n_remChannel! is a node cost. Passing over edge")
        return
    end
    isdirected = get_prop(mdg, edge, :directed)
    capacity = get_prop(mdg, edge, :capacity)
    if capacity > 1
        # Make sure capacity doesn't underflow 0.
        capacity - remHowMany >= 0 ? capacity = capacity - remHowMany : capacity = 0
        set_prop!(mdg, edge, :capacity, capacity)
        if isdirected == false
            set_prop!(mdg, edge.dst, edge.src, :capacity, capacity-1)
        end
    else
        rem_edge!(mdg, edge)
        if isdirected == false
            rem_edge!(mdg, edge.dst, edge.src)
        end
    end
    return
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
Given a path in the MetaDiNetwork, convert it to a path in the QNetwork
"""
function n_path(mdg::MetaDiGraph, path::Vector{Edge{Int}})::Vector{Edge{Int}}
    qpath = Vector{Edge}()
    pathLength = length(path)
    i = 0
    for edge in path
        if get_prop(mdg, edge, :isNodeCost) == true
        else
            src = edge.src; dst = edge.dst
            srcid = abs(get_prop(mdg, src, :qid))
            dstid = abs(get_prop(mdg, dst, :qid))
            push!(qpath, Edge(srcid, dstid))
        end
    end
    return qpath
end


"""
Given a literal path in the MetaGraph, remove it from the network, taking care that
channel bandwidth is reduced where applicable and making sure not to remove
edges corresponding to node costs.
"""
function n_removePath!(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}}; remHowMany = 1)::Nothing
    deadpool = []
    for edge in path
        if typeof(edge) == Vector{Tuple{Int, Int}}; edge = Edge(edge) end
        if get_prop(mdg, edge, :isNodeCost) == false
            n_remChannel!(mdg, edge)
        end
    end
    return
end

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
