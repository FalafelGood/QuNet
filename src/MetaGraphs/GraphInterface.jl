"""
Interface for manipulating the QNetwork at graph level. Mostly, this file consists
of wrapper functions for MetaGraphs (And by extention LightGraphs) API.
Exported functions have prefix "g_" to indicate they modify the graph at the
graph level.
"""

# Global vertex and edge meta attributes. Each vertex and edge in the graph
# will be initialised with these props by default:
vertexProps = Dict(:isChannel => false)
edgeProps = Dict(:isChannel => false)

"""
Map a node in the QuNet to a vertex in the graph
"""
function mapNodeToVert!(mdg::MetaDiGraph, nodeid::Int, v::Int)
    try
        (get_prop(mdg, :nodeToVert))[nodeid] = v
    catch err
        try
            delete!(get_prop(mdg, :nodeToVert), nodeid)
            (get_prop(mdg, :nodeToVert))[nodeid] = v
        catch err
            error("Unable to map node to vertex")
        end
    end
end


"""
Given a QNode's id, get the vertex corresponding to it. If no vertex exists,
return 0.
"""
function g_getVertex(mdg::MetaDiGraph, nodeid::Int)
    try
        return (get_prop(mdg, :nodeToVert))[nodeid]
    catch err
        return 0
    end
end


"""
Given a vertex in the graph, get the QNode corresponding to it.
If the vertex does not correspond to a QNode, return 0. Else if the vertex
doesn't exist in the network, return an error.
"""
function g_getNode(mdg::MetaDiGraph, v::Int)
    try
        return get_prop(mdg, v, :qid)
    catch err
        return 0
    end
end


"""
Add a vertex to the MetaDiGraph and instantiate the default properties from
the vertexProps dictionary.
"""
function g_addVertex!(g::AbstractMetaGraph)
    add_vertex!(g)
    idx = nv(g)
    set_props!(g, idx, vertexProps)
    return idx
end


function g_addVertex!(g::AbstractMetaGraph, d::Dict)
    add_vertex!(g)
    idx = nv(g)
    set_props!(g, idx, vertexProps)
    set_props!(g, nv(g), d)
    return idx
end


function g_addVertex!(g::AbstractMetaGraph, s::Symbol, v)
    add_vertex!(g)
    idx = nv(g)
    set_props!(g, idx, vertexProps)
    set_prop!(g, nv(g), s, v)
    return idx
end

"""
Add an edge to the MetaDiGraph and instantiate the default properties from
the edgeProps dictionary.
"""
function g_addEdge!(mdg::AbstractMetaGraph, src::Int, dst::Int)
    add_edge!(mdg, src, dst)
    set_props!(mdg, src, dst, edgeProps)
end


function g_hasEdge(mdg::AbstractMetaGraph, src::Int, dst::Int)
    return has_edge(mdg, src, dst)
end


function g_remEdge!(mdg::AbstractMetaGraph, edge::Tuple{Int, Int})
    return rem_edge!(mdg, edge[1], edge[2])
end

"""
Wrapper function for getting properties from meta graph.
"""
function g_getProp(mdg::AbstractMetaGraph, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, Symbol(prop))
end


# Duplicate code is kind of ugly here...
function g_getProp(mdg::AbstractMetaGraph, v::Int, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, v, Symbol(prop))
end


function g_getProp(mdg::AbstractMetaGraph, e::Edge, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, e, Symbol(prop))
end


function g_getProp(mdg::AbstractMetaGraph, s::Int, d::Int, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, s, d, Symbol(prop))
end


"""
Get the costs associated with an edge in the MetaDiGraph
"""
function g_edgeCosts(mdg::MetaDiGraph, edge::Union{Tuple{Int, Int}, Edge{Int}})::Costs
    # TODO: This function will not work for Tuple{Int, Int}!
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
Find the shortest path in terms of the specified cost field. Returns the network
path along with the associated costs.
"""
function g_shortestPath(mdg::MetaDiGraph, src::Int, dst::Int, cost::String)
    @assert Symbol(cost) in fieldnames(Costs)
    cost = addCostPrefix(cost)

    # Save original weightfield and set new weight to the cost
    orig_wf = weightfield(mdg)
    weightfield!(mdg, Symbol(cost))

    # Save original e_props
    orig_eprops = deepcopy(mdg.eprops)

    # Set channel weights to Inf if :active == false
    inactiveChannels = filter_vertices(mdg, :active, false)
    for chanVert in inactiveChannels
        srcNode = get_prop(mdg, chanVert, :src)
        dstNode = get_prop(mdg, chanVert, :dst)
        n_setChannelCosts(mdg, srcNode, dstNode, chanVert, Costs(Inf, Inf))
    end

    path = a_star(mdg, src, dst)

    # Reset weightfield and eprops
    weightfield!(mdg, orig_wf)
    mdg.eprops = orig_eprops

    pcosts = g_pathCosts(mdg, path)
    return path, pcosts
end


"""
Remove the inactive channels of a graph
"""
function g_removeInactiveChannels!(mdg::MetaDiGraph)
    function filterCondition(mdg, v)
        return get_prop(mdg, v, :isChannel) && !get_prop(mdg, v, :active)
    end
    inactiveChannels = collect(filter_vertices(mdg, filterCondition))
    for chanVert in inactiveChannels
        rem_vertex!(mdg, chanVert)
    end
end


"""
Remove the inactive Nodes of a graph
"""
function g_removeInactiveNodes(mdg::MetaDiGraph)
    function filterCondition(mdg, v)
        return !get_prop(mdg, v, :isChannel) && !get_prop(g, v, :active)
    end
    inactiveNodes = collect(filter_vertices(mdg, filterCondition))
    for nodeVert in inactiveNodes
        rem_vertex!(mdg, nodeVert)
    end
end
