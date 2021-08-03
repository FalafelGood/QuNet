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
Return true if an edge exists between the two nodes in the graph
representation of the network, and false otherwise. If isdirected = false,
this function returns true only if there also exists an edge in the reverse
direction.
"""
function g_hasChannel(mdg::MetaDiGraph, src::Int, dst::Int, isdirected = false)
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
Get the :id of a network node from the index of a graph vertex
"""
function n_index(mdg::MetaDiGraph, netidx)
    return mdg[netidx, :id]
end

"""
Reduce the channel capacity associated with an edge by one.
If the channel capacity is zero, remove the edge. If the channel is undirected,
operate on both directions.
"""
function g_remChannel!(mdg::MetaDiGraph, edge::Edge; remHowMany = 1)::Nothing
    if get_prop(mdg, edge, :isNodeCost) == true
        @warn ("edge in g_remChannel! is a node cost. Passing over edge")
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
Wrapper function for getting property from meta graph.
"""
function g_getProp(mdg::MetaDiGraph, prop::String)
    if prop in fieldnames(Costs)
        addCostPrefix!(prop)
    end
    return get_prop(mdg, Symbol(prop))
end

# Duplicate code is kind of ugly here...
function g_getProp(mdg::MetaDiGraph, v::Int, prop::String)
    if prop in fieldnames(Costs)
        addCostPrefix!(prop)
    end
    return get_prop(mdg, v, Symbol(prop))
end

function g_getProp(mdg::MetaDiGraph, e::Edge, prop::String)
    if prop in fieldnames(Costs)
        addCostPrefix!(prop)
    end
    return get_prop(mdg, e, Symbol(prop))
end

function g_getProp(mdg::MetaDiGraph, s::Int, d::Int, prop::String)
    if prop in fieldnames(Costs)
        addCostPrefix!(prop)
    end
    return get_prop(mdg, s, d, Symbol(prop))
end

"""
Get the costs associated with an edge in the MetaDiGraph
"""
function g_edgeCosts(mdg::MetaDiGraph, edge::Union{Tuple{Int, Int}, Edge{Int}})::Costs
    if typeof(edge) == Tuple{Int, Int}; edge = Edge(edge) end
    @assert has_edge(mdg, edge) == true "Edge not found in graph"
    ecosts = Costs()
    for costType in fieldnames(Costs)
        formattedCost = addCostPrefix(string(costType))
        cost = get_prop(mdg, edge, Symbol(formattedCost))
        setproperty!(ecosts, costType, cost)
    end
    return ecosts
end

"""
Given a path in the MetaDiGraph, return the associated costs
"""
function g_pathCosts(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}})::Costs
    pcosts = Costs()
    for edge in path
        ecosts = g_edgeCosts(mdg, edge)
        for costType in fieldnames(Costs)
            currentCost = getproperty(pcosts, costType)
            costToAdd = getproperty(ecosts, costType)
            setproperty!(pcosts, costType, currentCost + costToAdd)
        end
    end
    return pcosts
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
            srcid = abs(get_prop(mdg, src, :id))
            dstid = abs(get_prop(mdg, dst, :id))
            push!(qpath, Edge(srcid, dstid))
        end
    end
    return qpath
end

"""
Remove a path in the MetaDiGraph, taking care not to remove edges corresponding
with node costs
"""
function g_removePath!(mdg::MetaDiGraph, path::Union{Vector{Tuple{Int, Int}}, Vector{Edge{Int}}}; remHowMany = 1)::Nothing
    deadpool = []
    for edge in path
        if typeof(edge) == Vector{Tuple{Int, Int}}; edge = Edge(edge) end
        if get_prop(mdg, edge, :isNodeCost) == false
            g_remChannel!(mdg, edge)
        end
    end
    return
end

"""
Find the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function g_shortestPath(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)
    src = g_index(mdg, src)
    if get_prop(mdg, dst, :hasCost) == true
        dst = g_index(mdg, -dst)
    else
        dst = g_index(mdg, dst)
    end
    @assert Symbol(cost) in fieldnames(Costs)
    cost = addCostPrefix(cost)

    # Save original weightfield and set new weight to the cost
    orig_wf = weightfield(mdg)
    weightfield!(mdg, Symbol(cost))

    # Save original e_props
    orig_eprops = deepcopy(mdg.eprops)

    # Set edge weights to Inf if :active == false
    inactiveEdges = filter_edges(mdg, :active, false)
    for edge in inactiveEdges
        set_prop!(mdg, edge, Symbol(cost), Inf)
    end

    path = a_star(mdg, src, dst)

    # Reset weightfield and eprops
    weightfield!(mdg, orig_wf)
    mdg.eprops = orig_eprops

    pcosts = g_pathCosts(mdg, path)
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
function g_remShortestPath!(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)
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
    g_removePath!(mdg, path)
    return path, pcosts
end

"""
Return a graph with inactive channels removed
"""
function g_filterInactiveEdges(mdg::MetaDiGraph)
    # Filter out active edges
    activeEdges = collect(filter_edges(mdg, :active, true))
    # Filter out active edge properties
    newEprops = Dict(activeKey => mdg.eprops[activeKey] for activeKey in activeEdges)
    sdg = SimpleDiGraph(activeEdges)

    newMeta = MetaDiGraph(sdg, mdg.vprops, newEprops, mdg.gprops,
    mdg.weightfield, mdg.defaultweight, mdg.metaindex, mdg.indices)
    return newMeta
end

"""
Return a graph with channels in neighborhoods of inactive nodes removed.
Edges are much faster to filter out than nodes since none of the
"""
function g_filterInactiveVertices(mdg::MetaDiGraph)
    """
    Filter edges that are not connected to an innactive node
    """
    function edgeCondition(g, e)
        if (get_prop(g, e.src, :active) == true && get_prop(g, e.dst, :active) == true)
            return true
        end
        return false
    end

    activeEdges = collect(filter_edges(mdg, edgeCondition))
    # Filter out active edge properties
    newEprops = Dict(activeKey => mdg.eprops[activeKey] for activeKey in activeEdges)
    # Make new MetaDiGraph
    sdg = SimpleDiGraph(activeEdges)
    newMeta = MetaDiGraph(sdg, mdg.vprops, newEprops, mdg.gprops,
    mdg.weightfield, mdg.defaultweight, mdg.metaindex, mdg.indices)
    return newMeta
end
