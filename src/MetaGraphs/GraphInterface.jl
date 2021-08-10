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
function mapNodeToVert(mdg::MetaDiGraph, nodeid::Int, v::Int)
    (get_prop(mdg, :nodeToVert))[nodeid] = v
end

"""
Get the index of a graph vertex from the :qid of the network node.

Recall that if a node in the network has a cost then that cost is represented
by a directed edge that joins a source to a sink where
:qid[source] = -:qid[sink]

If issrc is set to false, this function returns the index corresponding to the
sink.
"""
function g_index(mdg::MetaDiGraph, graphidx::Int; issrc = true)
    if issrc == false
        graphidx = -graphidx
    end
    return mdg.metaindex[:qid][graphidx]
end

"""
Given a QNode's id, get the vertex corresponding to it
"""
function g_getVertex(mdg::MetaDiGraph, nodeid::Int)
    return (get_prop(mdg, :nodeToVert))[nodeid]
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
function g_addEdge!(mdg::MetaDiGraph, src::Int, dst::Int)
    add_edge!(mdg, src, dst)
    set_props!(mdg, src, dst, edgeProps)
end


function g_hasEdge(mdg::MetaDiGraph, src::Int, dst::Int)
    return has_edge(mdg, src, dst)
end

# """
# Get the index of a graph vertex from the :qid of the network node
# """
# function g_index(mdg::MetaDiGraph, netidx)
#     return mdg.metaindex[:qid][graphidx]
# end


function g_remEdge!(mdg::MetaDiGraph, edge::Tuple{Int, Int})
    return rem_edge!(mdg, edge)
end

"""
Wrapper function for getting properties from meta graph.
"""
function g_getProp(mdg::MetaDiGraph, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, Symbol(prop))
end


# Duplicate code is kind of ugly here...
function g_getProp(mdg::MetaDiGraph, v::Int, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, v, Symbol(prop))
end


function g_getProp(mdg::MetaDiGraph, e::Edge, prop::String)
    if prop in fieldnames(Costs)
        QuNet.addCostPrefix!(prop)
    end
    return get_prop(mdg, e, Symbol(prop))
end


function g_getProp(mdg::MetaDiGraph, s::Int, d::Int, prop::String)
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
