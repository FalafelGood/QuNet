weights = SimpleWeightedGraphs.weights

"""
Find the shortest path between two nodes of an AbstractGraph by using the
\'a star\' method. Returns a vector of AbstractEdge. If no path is found,
returns an empty vector.
"""
function shortest_path(graph::AbstractGraph, src::Int64, dst::Int64)
    path = a_star(SimpleDiGraph(weights(graph)), src, dst, weights(graph))
    return path
end
# Change SimpleDiGraph to SimpleWeightedDiGraph

"""
Finds the total weight/length of a path for a given AbstractGraph.
Not to be confused with get_pathcv(), which finds the vector of costs for a
path in a QNetwork.

!!! warning
    For whatever reason, SimpleWeightedDiGraph indexes weights with [dest, src].
    Keep in mind this path_length will likely not work if you pass in anything
    but a SimpleWeightedDiGraph.
"""
function path_length(graph::AbstractGraph, path::Vector{Tuple{Int64, Int64}})::Float64
    dist = 0.0
    for edge in path
        # SimpleWeightedDiGraph indexes by [dst, src]. Be careful here!
        dist += graph.weights[edge[2], edge[1]]
    end
    return dist
end


function path_length(graph::AbstractGraph, path::Vector{LightGraphs.SimpleGraphs.SimpleEdge{Int64}})::Float64
    dist = 0.0
    for edge in path
        # SimpleWeightedDiGraph indexes by [dst, src]. Be careful here!
        dist += graph.weights[edge.dst, edge.src]
    end
    return dist
end

"""
Removes the shortest path between two nodes of an abstract graph and returns the
path along with its length. If no path exists, returns nothing for both.
"""
function remove_shortest_path!(graph::AbstractGraph, src::Int64, dst::Int64)

    # Get shortest path. If no path exists, return nothing for path and length
    path = shortest_path(graph, src, dst)
    if length(path) == 0
        return nothing
    end

    path_len = path_length(graph, path)

    # Remove path
    for edge in path
        status = hard_rem_edge!(graph, edge.src, edge.dst)
        if status == false
            error("Failed to remove edge in path")
        end
    end

    return path, path_len
end


"""
Removes the shortest path between two nodes of a QNetwork *with respect to a
given cost* and returns the path with its corresponding cost vector.
"""
function remove_shortest_path!(network::QNetwork, cost_id::String, src::Int64, dst::Int64)
    @assert cost_id in keys(zero_costvector()) "Invalid cost"

    # Find shortest path in terms of the given cost
    g = network.graph[cost_id]
    path = shortest_path(g, src, dst)
    # If no path exists, return nothing for path and path_cv
    if length(path) == 0
        return nothing, nothing
    end

    # Find the costs associated with the path
    path_cv = get_pathcv(network, path)

    # Remove the path from the network graphs
    for cost_id in keys(zero_costvector())
        graph = network.graph[cost_id]
        for edge in path
            status = hard_rem_edge!(graph, edge.src, edge.dst)
            if status == false
                error("Failed to remove edge in path")
            end
        end
    end
    return path, path_cv
end

"""
Remove the shortest_path of a TemporalGraph, making sure not to remove the edge
between the asynchronous node and its temporal counterpart. When specifying
src and dst, specify them as you would if the graph were non-temporal. E.G. if
you have a 1x2 network with 2 timesteps and you wanted to find the best path
between the two nodes, you would specify src:1, dst:2
"""
function remove_shortest_path!(tempnet::QuNet.TemporalGraph, cost_id::String,
    src::Int64, dst::Int64)

    @assert cost_id in keys(zero_costvector()) "Invalid cost"

    # Check that src and dst are nodes within range(1, size-of-static-graph)
    if (src > tempnet.nv && dst > tempnet.nv)
    # if (src <= tempnet.nv * tempnet.steps || dst <= tempnet.nv * tempnet.steps)
        @assert 1==0 "(src::$src) and (dst::$dst) nodes must be asynchronous"
    end

    # Reindex src and dst so that they point to their asynchronus counterparts
    src += tempnet.nv * tempnet.steps
    dst += tempnet.nv * tempnet.steps

    # Find shortest path in terms of the given cost
    t = tempnet.graph[cost_id]
    path = shortest_path(t, src, dst)

    # If length(path) == 0, no path exists. Return nothing
    if length(path) == 0
        return nothing, nothing
    end

    # Since path runs from asynchronus nodes,
    # pop the path on either end so asynchronus edges aren't removed
    popfirst!(path)
    pop!(path)

    # Find the costs associated with the path:
    path_cv = get_pathcv(tempnet, path)

    # Remove the shortest path
    for cost_id in keys(zero_costvector())
        graph = tempnet.graph[cost_id]
        for edge in path
            status = hard_rem_edge!(graph, edge.src, edge.dst)
            if status == false
                error("Failed to remove edge in path")
            end
        end
    end
    return path, path_cv
end

"""
greedy_multi_path! is an entanglement routing strategy for a quantum network
with n end user pairs.

1. Each user pair has an associated "bundle" of paths that starts out empty.
For each user pair, find the shortest path between them, and add its cost to the
bundle. If no path exists, add "nothing" to the bundle.

2. When all the bundles are filled up to the maximum number "maxpaths", use an
entanglement purification method between the path costs. Add the resulting cost
vector to the array pur_paths. If no paths exist for a given bundle, increment
the collision count by one, and add "nothing" to pur_paths

3. Return the array of purified cost vectors and the collision count.
"""
function greedy_multi_path!(network::Union{QNetwork, QuNet.TemporalGraph}, purification_method,
    users, maxpaths::Int64=3)

    # List of paths for each userpair
    pathset = [Vector() for i in 1:length(users)]
    # List of path costs for each userpair
    path_costs = [Vector{Dict{Any,Any}}() for i in 1:length(users)]

    for i in 1:maxpaths
        for (userid, user) in enumerate(users)
            src = user[1]; dst = user[2]
            # Remove the shortest path in terms of Z-dephasing and get its cost vector.
            path, path_cv = remove_shortest_path!(network, "Z", src, dst)
            # If pathcv is nothing, no path was found.
            if path_cv == nothing
                break
            else
                push!(pathset[userid], path)
                push!(path_costs[userid], path_cv)
            end
        end
    end

    # A tally of the number of paths each end-user purifies together.
    pathuse_count = [0 for i in 0:maxpaths]
    # An array of purified cost vectors for each end-user.
    pur_paths = []

    # Purify end-user paths
    for userpaths in path_costs
        # Increment the tally for the number of paths beting purified
        len = length(userpaths)
        pathuse_count[len + 1] += 1
        # If len == 0, no paths were found between the end-user.
        if len == 0
            push!(pur_paths, nothing)
        # Otherwise, purify the paths
        else
            purcost::Dict{Any, Any} = purification_method(userpaths)
            # Convert purcost from decibels to metric form
            purcost = convert_costs(purcost)
            push!(pur_paths, purcost)
        end
    end
    return pathset, pur_paths, pathuse_count
end


# There's really no need for this function in principle
# It's exacttly identical to the other function, except it takes a different type
# function greedy_multi_path!(tempnet::QuNet.TemporalGraph, purification_method,
#     users, maxpaths::Int64=3)
#
#     # List of path costs for each userpair, where top-level index is userpair.
#     # v = Vector{Dict{Any, Any}}()
#     # path_costs = fill(v, length(users))
#     path_costs = [Vector{Dict{Any,Any}}() for i in 1:length(users)]
#
#     for i in 1:maxpaths
#
#         for (userid, user) in enumerate(users)
#             src = user[1]
#             dst = user[2]
#
#             # Remove the shortest path (In terms of dephasing)
#             pathcv = remove_shortest_path!(tempnet, "Z", src, dst)
#             # If pathcv is nothing, no path was found.
#             if pathcv == nothing
#                 break
#             else
#                 push!(path_costs[userid], pathcv)
#             end
#         end
#     end
#
#     # Purify each path set, checking for collisions
#     collisions = 0
#     # Vector{Dict{Any, Any}}()
#     pur_paths = []
#
#     for userpaths in path_costs
#         # If length(userpaths) == 0, no paths were found. No purification possible.
#         if length(userpaths) == 0
#             collisions += 1
#             push!(pur_paths, nothing)
#         # Otherwise, purify.
#         else
#             purcost::Dict{Any, Any} = purification_method(userpaths)
#             # Convert purcost from decibels to metric form
#             purcost = convert_costs(purcost)
#             push!(pur_paths, purcost)
#         end
#     end
#     return pur_paths, collisions
# end
