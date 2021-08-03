"""
Wrapper functions for MetaGraphs (And by extention LightGraphs) API
Exported functions have prefix "g_" to indicate they modify the graph level
"""

"""
Interface functions for the MetaDiGraph representation of the QNetwork.
Exported functions have prefix "g_" by convention
"""
function g_addEdge!(mdg::MetaDiGraph, src::Int, dst::Int)
    return add_edge!(mdg, src, dst)
end


function g_hasEdge(mdg::MetaDiGraph, src::Int, dst::Int)
    return has_edge(mdg, src, dst)
end


"""
Get the index of a graph vertex from the :id of the network node
"""
function g_index(mdg::MetaDiGraph, netidx)
    return mdg.metaindex[:id][graphidx]
end


function g_remEdge!(mdg::MetaDiGraph, edge::Tuple{Int, Int})
    return rem_edge!(mdg, edge)
end


"""
Add prefix "CostΔ" onto a cost name so it can be accessed by g_getProp
"""
function addCostPrefix(cost::String)::String
    cost = "CostsΔ" * cost
    return cost
end


"""
Wrapper function for getting properties from meta graph.
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
function g_edgeCosts(mdg::MetaDiGraph, edge::Tuple{Int, Int})::Costs
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
    # if get_prop(mdg, :nodeCosts) == true
    #     # Filter out edges corresponding to node costs
    #     path = n_path(mdg, path)
    # end
    return path, pcosts
end

"""
Get the index of a graph vertex from the :id of the network node
"""
function g_index(mdg::MetaDiGraph, graphidx)
    return mdg.metaindex[:id][graphidx]
end

"""
Given src and dst in the network,
"""
function g_getChannel(g_src::Int, g_dst::Int)::Tuple{Int, Int}
    # TODO
end
