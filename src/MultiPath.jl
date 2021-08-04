"""
TODO: OUTDATED
Methods for multi-user multi-path routing in Quantum networks
"""

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
function greedy_multi_path!(network::QNetwork, purification_method,
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


function greedy_multi_path!(network::QuNet.TemporalGraph, purification_method,
    users, maxpaths::Int64=3)

    # For TemporalGraph, paths must arrive at identical time_depth
    # route_layer_known is false until first path is routed.
    route_layer_known = false

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

            # If we found a path, and we haven't fixed a routing time:
            if path_cv != nothing && route_layer_known == false
                route_layer_known = true
                last_edge = last(path)
                # If last node of the path is asynchronus:
                    # Remove all async edges except for the one at T = depth
                    # This means all future paths will have to route to the same time
                if last_edge.dst > network.nv * network.steps
                    node = last_edge.src
                    depth = QuNet.node_timedepth(T.nv, T.steps, node)
                    # Remove all asynchronus edges except for that depth
                    QuNet.fix_async_nodes_in_time(T, [node])
                end
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


"""
Find the maximum timedepth reached by a given pathset
"""
function max_timedepth(pathset, T)
    max_depth = 1
    for bundle in pathset
        for path in bundle
            edge = last(path)
            node = edge.dst
            # Check if node is temporal. If it is, use 2nd last node in path instead
            if node > T.nv * T.steps
                node = edge.src
            end
            # use node - 1 here because if node % T.nv == 0, depth is off by one
            depth = QuNet.node_timedepth(T.nv, T.steps, node)
            if depth > max_depth
                max_depth = depth
            end
        end
    end
    return max_depth
end
