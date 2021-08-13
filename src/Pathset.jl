"""
Pathset is a collection of paths that all start at some vertex u and end at some
vertex v. The purpose of the pathset is to organise / keep track of paths that
are purified together.
"""
@def_structequal struct Pathset
    src::Int
    dst::Int
    paths::Vector{Vector{Tuple{Int, Int}}}
    freqs::Vector{Int}

    function Pathset(paths::Vector{Vector{Tuple{Int, Int}}}, freqs::Vector{Int} = ones(Int64, length(paths)))
        unique!(paths)
        lp = length(paths)
        @assert lp == length(freqs) "Number of unique paths does not match frequency list."
        # Pretty ugly, know a better way?
        src = first(first(paths[1]))
        dst = last(last(paths[1]))
        @assert all(first(first(p)) == src && last(last(p)) == dst for p in paths) "Paths don't all start and finish at the same src and dst."
        glob = []
        for i in 1:lp
            if !(freqs[i] < 1)
                push!(glob, (paths[i], freqs[i]))
            end
        end
        # Sort everything to guarentee uniqueness.
        # Later this will let us query if two Pathsets are equal with @struct_equal
        function sortmethod(globule)
            DST = 2
            path = globule[1]
            # Length will sort most paths out
            len = length(path)
            # .. but two paths could have same length. Need to sort by :qid of nodes in path too
            # Concatanate dst id's to a single number and normalise so < 1
            idstring = ""
            for (id, edge) in enumerate(path)
                idstring *= string(edge[DST])
            end
            idcost = parse(Int64, idstring) / 10^length(idstring)
            return len + idcost
        end
        PATH_IDX = 1
        FREQ_IDX = 2
        sort!(glob, by = globule -> sortmethod(globule))
        paths = collect(glob[i][PATH_IDX] for i in 1:lp)
        freqs = collect(glob[i][FREQ_IDX] for i in 1:lp)
        new(src, dst, paths, freqs)
    end
end

"""
Remove the pathset from the graph
"""
function remPathset(mdg::MetaDiGraph, pathset::Pathset)
    function tuplesToEdges(path)
        edgepath = Vector{Edge{Int}}()
        for step in path
            push!(edgepath, Edge(step[1], step[2]))
        end
        return edgepath
    end
    for (idx, path) in enumerate(pathset.paths)
        path = tuplesToEdges(path)
        n_removeVertexPath!(mdg, path, remHowMany = pathset.freqs[idx])
    end
end
