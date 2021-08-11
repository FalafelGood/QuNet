"""
Interface for manipulating the QNetwork at graph level. Mostly, this file consists
of wrapper functions for MetaGraphs (And by extention LightGraphs) API.
Exported functions have prefix "g_" to indicate they modify the graph at the
graph level.
"""

# Global vertex and edge meta attributes. Each vertex and edge in the graph
# will be initialised with these props by default:
vertexProps = Dict(:hasCost => false, :isChannel => false)
edgeProps = Dict(:isNodeCost => false, :isChannel => false)

"""
Map a node in the QuNet to a vertex in the graph
"""
function mapNodeToVert!(mdg::MetaDiGraph, nodeid::Int, v::Int)
    (get_prop(mdg, :nodeToVert))[nodeid] = v
end

# TODO: Needed?
# """
# Get the index of a graph vertex from the :qid of the network node.
#
# Recall that if a node in the network has a cost then that cost is represented
# by a directed edge that joins a source to a sink where
# :qid[source] = -:qid[sink]
#
# If issrc is set to false, this function returns the index corresponding to the
# sink.
# """
# function g_index(mdg::MetaDiGraph, graphidx::Int; issrc = true)
#     if issrc == false
#         graphidx = -graphidx
#     end
#     return mdg.metaindex[:qid][graphidx]
# end

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
If a Qnode has a cost, this function returns the vertex corresponding to the cost.
Otherwise, returns the vertex corresponding to the Qnode. If no node is found,
throws an error
"""
function g_CostVertex(mdg::MetaDiGraph, nodeid::Int)
    v = g_getVertex(mdg, nodeid)
    if v == 0
        error("Node not found in network")
    end
    if get_prop(mdg, :nodeCosts) == true && get_prop(mdg, v, :hasCost) == true
        return g_getVertex(-nodeid)
    end
    return v
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

# """
# Get the index of a graph vertex from the :qid of the network node
# """
# function g_index(mdg::MetaDiGraph, netidx)
#     return mdg.metaindex[:qid][graphidx]
# end


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
