"""
Routing methods for benchmarking quantum networks
"""

# TODO

"""
greedyMultiPath! is an entanglement routing strategy for multiple user-pairs in
a quantum network.

1. Each user pair has an associated Pathset that starts out empty. For each
userpair, the shortest path between them is found in terms of dF and the path
is added to the pathset. If no path exists, nothing is added. This continues
until one of the following criteria is met:
    + The pathsets are filled with the threshold number of paths (given by maxpaths)

2. Entanglement purification is performed over all the pathsets, removing the
paths without adding purification channels.

3. If a pathset is empty, no path was found between the end-user pair.

2. When all the bundles are filled up to the maximum number "maxpaths", use an
entanglement purification method between the path costs. Add the resulting cost
vector to the array pur_paths. If no paths exist for a given bundle, increment
the collision count by one, and add "nothing" to pur_paths
3. Return the array of purified cost vectors and the collision count.
"""
function greedyMultiPath!(mdg::MetaDiGraph, userpairs::Array{Tuple{Int,Int}};
        maxpaths::Int64 = 4)

        routingData = [Pathset() for i in 1:length(userpairs)]
        # TODO:
        routingCosts = Vector{Vector{Costs}}()

        for pathnum in 1:maxpaths
            for (userid, user) in enumerate(userpairs)
                srcNode = user[1]; dstNode = user[2]
                srcVert = g_getVertex(mdg, srcNode)
                dstVert = g_getVertex(mdg, dstNode)
                # Find shortest path in terms of dF and remove it from graph
                vPath, pcosts = n_remShortestPath!(mdg, srcVert, dstVert, "dF")
                vPath = edgesToTuples(vPath)
                pathset = routingData[userid]
                pathidx = QuNet.findPathInPathset(pathset, vPath)
                # If path does not exist in Pathset, add it to pathset
                if pathidx == 0
                    push!(pathset.paths, vPath)
                    push!(pathset.freqs, 1)
                else
                    # Update frequency for path
                    pathset.freqs[pathidx] += 1
                end
            end
        end

    # Purify Costs from pathsets
    for pathset in routingData
        costs = QuNet.purifyCosts(mdg, pathset)
        push!(routingCosts, costs)
    end
    return routingData, routingCosts
end
