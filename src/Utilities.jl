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

function edgesToTuples(path)
    tuplepath = Vector{Tuple{Int, Int}}()
    for step in path
        src = step.src
        dst = step.dst
        push!(tuplepath, (src, dst))
    end
    return tuplepath
end
