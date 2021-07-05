"""
Interface functions
"""

"""
Return a graph with inactive channels removed
"""
function filterInactiveEdges(mdg::MetaDiGraph)
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
function filterInactiveVertices(mdg::MetaDiGraph)
    """
    Filter edges that are not connected to an innactive node
    """
    function edgeCondition(g, e)
        if (get_prop(g, e.src, :active) == true && get_prop(g, e.src, :active) == true)
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

# function gAttr(mdg::MetaDiGraph, )
#     # TODO
# end#
#
# function gGetVertex(mdg::MetaDiGraph, id::Int)
#     # TODO
# end
#
# function gGetCosts()
#     # TODO
# end
#
# function gHasEdge()
#     # TODO
# end
#
# function gHasChannel()
#     # TODO
# end
#
# function gAddChannel!()
#     # TODO
# end
#
# function gRemoveChannel!(mdg::MetaDiGraph)
#     # TODO
# end
