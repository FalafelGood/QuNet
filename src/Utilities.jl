"""
Miscelanious functions that don't belong anywhere else
"""

"""
Convert a path of tuples to a path of edges
"""
function tuplesToEdges(path)
    edgepath = Vector{Edge{Int}}()
    for step in path
        push!(edgepath, Edge(step[1], step[2]))
    end
    return edgepath
end


"""
Niche function to hide some ugly code.

Basically, the src and dst attributes of a vertex path require some finessing
in order to get the vertices needed to add or else manipulate a channel between
the end nodes.
"""
function channelEndsFromVertexPath(mdg::MetaDiGraph, pathSrc, pathDst)
    srcVert = g_CostVertex(mdg, abs(g_getNode(mdg, pathSrc)))
    dstVert = g_getVertex(mdg, abs(g_getNode(mdg, pathDst)))
    return srcVert, dstVert
end
