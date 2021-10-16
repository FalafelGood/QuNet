"""
Return average average value for an array of cost vectors.
If the length of the input is less than 1, mean is not well defined,
the key values returned are 'nothing'.
"""
function dict_average(dict_list)
    avcosts = zero_costvector()

    if length(dict_list) == 0
        for cost_type in keys(avcosts)
            avcosts[cost_type] = NaN
        end
        return avcosts
    end

    for cost_type in keys(avcosts)
        costs = collect(map(x->x[cost_type], dict_list))
        avcosts[cost_type] = mean(costs)
    end
    return avcosts
end

"""
Return average standard error for an array of cost vectors.
If the length of the input is less than 2, error is not well defined,
the key values returned are 'nothing'.
"""
function dict_err(dict_list)
    averr = zero_costvector()
    len = length(dict_list)

    if len < 2
        for cost_type in keys(averr)
            averr[cost_type] = NaN
        end
        return averr
    end

    for cost_type in keys(averr)
        costs = collect(map(x->x[cost_type], dict_list))
        averr[cost_type] = std(costs)/(sqrt(length(costs)))
    end
    return averr
end

function percentage_error(main_dict, error_dict)
    perc_dict = Dict()
    for key in keys(main_dict)
        perc_dict[key] = error_dict[key] / main_dict[key]
    end
    return perc_dict
end


# """Generate a list of user_pairs for a QNetwork"""
# function make_user_pairs(net::QNetwork, num_pairs::Int)::Vector{Tuple{Int64, Int64}}
#     num_nodes = length(net.nodes)
#     @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
#     rand_space = Array(collect(1:num_nodes))
#     pairs = Vector{Tuple}()
#     i = 0
#     while i < num_pairs
#         idx = rand(1:length(rand_space))
#         u = rand_space[idx]
#         deleteat!(rand_space, idx)
#         idx = rand(1:length(rand_space))
#         v = rand_space[idx]
#         deleteat!(rand_space, idx)
#         chosen_pair = (u, v)
#         push!(pairs, chosen_pair)
#         i += 1
#     end
#     return pairs
# end

# TODO: This is probably a better function than above
function make_user_pairs(net::QNetwork, num_pairs::Int; node_list=nothing)::Vector{Tuple{Int64, Int64}}
    num_nodes = length(net.nodes)
    @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
    if node_list != nothing
        rand_space = node_list
    else
        rand_space = Array(collect(1:num_nodes))
    end
    pairs = Vector{Tuple}()
    i = 0
    while i < num_pairs
        idx = rand(1:length(rand_space))
        u = rand_space[idx]
        deleteat!(rand_space, idx)
        idx = rand(1:length(rand_space))
        v = rand_space[idx]
        deleteat!(rand_space, idx)
        chosen_pair = (u, v)
        push!(pairs, chosen_pair)
        i += 1
    end
    return pairs
end

"""
Generate a list of user_pairs for a square grid network, ensuring that there is an
edge buffer of a given thickness.
"""
function make_user_pairs_wbuffer(squarenet::QNetwork, num_pairs::Int; buffer::Int=1)::Vector{Tuple{Int64, Int64}}
    num_nodes = length(squarenet.nodes)
    d = sqrt(num_nodes)
    @assert isinteger(d) "Grid network is not square"
    @assert buffer > 0
    @assert d - 2 * buffer > 1 "Gridsize too small for given buffer"
    rand_space = Array(collect(0:num_nodes-1))
    # Filter out nodes in the margin
    # NOTE Cool trick: n % d == x coord, n ÷ d == y coord
    filter!(i -> (buffer <= (i%d)) || (buffer <= (i÷d)) || (i%d < d-buffer) || (i÷d < d-buffer), rand_space)
    # Set first index to 1
    rand_space .+ 1
    pairs = make_user_pairs(squarenet, num_pairs, node_list=rand_space)
    return pairs
end


"""
Generate a list of end-users for a TemporalGraph.
src_layer and dst_layer specify the temporal locations of the source and dst nodes
respectively. The default value for these is -1, which indicates the end-users should
be asynchronus.
"""
function make_user_pairs(net::QuNet.TemporalGraph, num_pairs::Int;
    src_layer::Int64=-1, dst_layer::Int64=-1)::Vector{Tuple{Int64, Int64}}

    num_nodes = net.nv
    @assert num_nodes >= num_pairs*2 "Graph space too small for number of pairs"
    @assert dst_layer <= net.steps "dst_layer must be between 1 and $(net.steps) -- or -1 for async nodes"

    rand_space = Array(collect(1:num_nodes))
    pairs = Vector{Tuple}()
    i = 0
    while i < num_pairs
        # Random source
        idx = rand(1:length(rand_space))
        u = rand_space[idx]
        deleteat!(rand_space, idx)

        # Random dest
        idx = rand(1:length(rand_space))
        v = rand_space[idx]
        deleteat!(rand_space, idx)

        # Update u and v to point to the specified source and dest layers
        # If src_layer == -1, index to async_nodes
        if src_layer == -1
            u += num_nodes * net.steps
        elseif src_layer > 0
            u += (src_layer - 1) * num_nodes
        else
            error("Invalid src_layer. Choose from {1, ..., T.steps} or -1 for asynchronus nodes")
        end

        if dst_layer == -1
            v += num_nodes * net.steps
        elseif dst_layer > 0
            v += (dst_layer - 1) * num_nodes
        else
            error("Invalid dst_layer. Choose from {1, ..., T.steps} or -1 for asynchronus nodes")
        end

        chosen_pair = (u, v)
        push!(pairs, chosen_pair)
        i += 1
    end
    return pairs
end

"""
Given a tally for the number of paths used by each end-user in a greedy_protocol:
(i.e. [3,4,2,1] meaning 3 end-users used no paths, 4, end-users used 1 path, etc.)
This function finds the average number of paths used in the protocol.
"""
function ave_paths_used(pathuse_count::Vector{Float64})
    ave_pathuse = 0.0
    len = length(pathuse_count)
    for i in 1:len
        ave_pathuse += (i-1) * pathuse_count[i]
    end
    ave_pathuse = ave_pathuse / sum(pathuse_count)
    return ave_pathuse
end


"""
Takes a network as input and return greedy_multi_path! performance statistics for some number of
random user pairs. Ensure graph is refreshed before starting.
"""
function net_performance(network::Union{QNetwork, QuNet.TemporalGraph},
    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
    dst_layer::Int64=-1, edge_perc_rate=0.0, get_apd=false, get_postman=false,
    async_cost=1)

    # Sample of average routing costs between end-users
    ave_cost_data = []
    # Sample of path usage statistics for the algorithm
    pathcount_data = []
    # number of paths found by the last pair in the network
    last_count = []
    # Average distances between userpairs in the network.
    ave_path_distance = []
    ave_path_distance_err = []
    # Average manhattan distances between userpairs post-selected on paths existing
    ave_postman = []
    ave_postman_err = []
    # List of pathlengths > 0 for every trial, and every userpair.
    pathlengths = []
    shortest_avail_path = []

    for i in 1:num_trials
        net = deepcopy(network)

        # Generate random communication pairs
        if typeof(network) == TemporalGraph
            user_pairs = make_user_pairs(network, num_pairs, src_layer=src_layer, dst_layer=dst_layer)
            # Add asynchronus nodes to the network copy
            add_async_nodes!(net, user_pairs, ϵ=async_cost)
        else
            user_pairs = make_user_pairs(network, num_pairs)
        end

        # Percolate edges
        # WARNING: Edge percolation will not be consistant between temporal layers
        # if typeof(net) = QuNet.TemporalGraph
        if edge_perc_rate != 0.0
            @assert 0 <= edge_perc_rate <= 1.0 "edge_perc_rate out of bounds"
            net = QuNet.percolate_edges(net, edge_perc_rate)
            refresh_graph!(net)
        end

        # Get data from greedy_multi_path
        pathset, routing_costs, pathuse_count, lastpair_numpaths = QuNet.greedy_multi_path!(net, purify, user_pairs, max_paths)

        # Add values to ave_path_difference
        if get_apd == true
            add_man_dists!(network, pathset, user_pairs, ave_path_distance)
        end

        # Add values to add_postman_dists!
        if get_postman == true
            add_postman_dists!(network, pathset, user_pairs, ave_postman)
        end

        push!(last_count, lastpair_numpaths)

        # # Collect path lengths from pathset, add them to pathlengths
        # for user in pathset
        #     for path in user
        #         l = length(path)
        #         if l != 0
        #             push!(pathlengths, l)
        #         end
        #     end
        # end

        # Filter out entries where no paths were found and costs are not well defined
        filter!(x->x!=nothing, routing_costs)

        # If the mean is well defined, average the routing costs and push to ave_cost_data
        if length(routing_costs) > 0
            # Average the data
            ave = dict_average(routing_costs)
            push!(ave_cost_data, ave)
        end
        push!(pathcount_data, pathuse_count)
    end

    # Find the mean and standard error of ave_cost_data. Call this the performance
    performance = dict_average(ave_cost_data)
    performance_err = dict_err(ave_cost_data)
    # Get percentage error from standard error:
    perc_err = percentage_error(performance, performance_err)

    # Find the mean and standard error of the path usage statistics:

    # Usage:
        # Each entry in pathcount_data is a vector of Ints of length (max_paths + 1)
        # An example entry is [3, 4, 3, 1]
        # Where 3 end-users found 0 paths, 4 end-users found 1 path, etc.
        # Given a collection of path statistics, ie. [[0, 1, 2, 1], [0, 0, 3, 0], [0, 1, 2, 1]]
        # we want to return vectors of average path usage with associated error:
        # ie. [0, 0.666, 2.333, 0.666] for means
    ave_pathcounts = [0.0 for i in 0:max_paths]
    ave_pathcounts_err = [0.0 for i in 0:max_paths]

    for i in 1:max_paths+1
        data = [pathcount_data[j][i] for j in 1:num_trials]
        ave_pathcounts[i] = mean(data)
        ave_pathcounts_err[i] = std(data)/(sqrt(length(data)))
    end

    # Convert costs from decibelic to metric form
    metric_performance = convert_costs(performance)

    # Get metric error from percentage error:
    metric_err = Dict()
    for key in keys(perc_err)
        metric_err[key] = perc_err[key] * metric_performance[key]
    end

    # Get stats for ave_lastcount
    ave_lastcount = mean(last_count)

    # Get stats for num_zeropaths
    num_zeropaths = count(i->(i==0), last_count)

    # ave_path_distance = mean(pathlengths)
    # ave_path_distance_err = sqrt(var(pathlengths)/num_trials)

    # Get stats for apd
    if get_apd == true
        ave_path_distance_err = sqrt(var(ave_path_distance)/num_trials)
        ave_path_distance = mean(ave_path_distance)
        # sqrt(var(ave_path_distance)/float(num_trials))
    end

    # Get stats for postman
    if get_postman == true
        ave_postman_err = sqrt(var(ave_postman)/num_trials)
        ave_postman = mean(ave_postman)
    end

    # return performance, performance_err, ave_pathcounts, ave_pathcounts_err
    # # TODO:
    return metric_performance, metric_err, ave_pathcounts, ave_pathcounts_err, ave_lastcount, num_zeropaths,
    ave_path_distance, ave_path_distance_err, ave_postman, ave_postman_err
end

# Current version
# Add manhattan distances for given network and userpairs onto man_paths array
# Find L1 distance:
#   For each element in pathset, check if path exists
#   If path exists, find L1 distance
#   Add L1 distance to relevant array
function add_man_dists!(network::QNetwork, pathset, userpairs, man_paths)
    g = network.graph["Z"]
    for (pairidx, paths) in enumerate(pathset)
        if length(paths) != 0
            pair = userpairs[pairidx]
            p = shortest_path(g, pair[1], pair[2])
            l = length(p)
            push!(man_paths, l)
        end
    end
end

# Shortest availible path
# For each element in pathset,
    # Check if path exists
    # If path exists, get length of first path
    # Add path to array
function add_postman_dists!(network, pathset, userpairs, postman_paths)
    for (idx, pair) in enumerate(pathset)
        if length(pair) != 0
            l = length(first(pair))
            push!(postman_paths, l)
        end
    end
end

# # Add manhattan distances for given network and userpairs onto man_paths array
# function add_man_dists!(network::QNetwork, userpairs, man_paths)
#     g = network.graph["Z"]
#     for pair in userpairs
#         path = shortest_path(g, pair[1], pair[2])
#         l = length(path)
#         if l != 0
#             push!(man_paths, l)
#         end
#     end
# end

# Add manhattan distances for given network and userpairs post-selected
# path between userpairs existing in percolated network.
# TODO: Include competition effects.
# function add_postman_dists!(network::QNetwork, perc_network::QNetwork, userpairs, postman_paths)
#     gperc = perc_network.graph["Z"]
#     g = network.graph["Z"]
#     for pair in userpairs
#         path = shortest_path(gperc, pair[1], pair[2])
#         l = length(path)
#         if l != 0
#             # Path exists, therefore find ave manhattan distance
#             path = shortest_path(g, pair[1], pair[2])
#             l = length(path)
#             push!(postman_paths, l)
#         end
#     end
# end

# function add_postman_dists!(network, pathset, userpairs, postman_paths)
#     kill_list = []
#     filtered_pairs = deepcopy(userpairs)
#     for (idx, pair) in enumerate(pathset)
#         if length(pair) != 0
#             push!(kill_list, idx)
#         end
#     end
#     deleteat!(filtered_pairs, kill_list)
#     add_man_dists!(network, filtered_pairs, postman_paths)
# end

"""
Takes a network as input and returns greedy_multi_path! heatmap data for
some number of user pairs. (i.e. a list of efficiency fidelity coordinates
for all end users over all num_trials)
"""
function heat_data(network::Union{QNetwork, QuNet.TemporalGraph},
    num_trials::Int64, num_pairs::Int64; max_paths=3, src_layer::Int64=-1,
    dst_layer::Int64=-1, edge_perc_rate=0.0)

    # e,f coords for all end users over all num_trials
    coord_list = []

    for i in 1:num_trials
        println("Collecting data for trial $i")
        net = deepcopy(network)

        # Generate random communication pairs
        if typeof(network) == TemporalGraph
            user_pairs = make_user_pairs(network, num_pairs, src_layer=src_layer, dst_layer=dst_layer)
            # Add asynchronus nodes to the network copy
            add_async_nodes!(net, user_pairs)
        else
            user_pairs = make_user_pairs(network, num_pairs)
        end

        # Percolate edges
        # WARNING: Edge percolation will not be consistant between temporal layers
        # if typeof(net) = QuNet.TemporalGraph
        if edge_perc_rate != 0.0
            @assert 0 <= edge_perc_rate <= 1.0 "edge_perc_rate out of bounds"
            net = QuNet.percolate_edges(net, edge_perc_rate)
            refresh_graph!(net)
        end

        # Get data from greedy_multi_path
        dummy, routing_costs, pathuse_count = QuNet.greedy_multi_path!(net, purify, user_pairs, max_paths)

        # Filter out entries where no paths were found and costs are not well defined
        filter!(x->x!=nothing, routing_costs)

        # Put end-user costs into tuples (e, f)
        for usercost in routing_costs
            coord = Vector{Float64}()
            push!(coord, usercost["loss"])
            push!(coord, usercost["Z"])
            # Add this new coordinate to the list
            push!(coord_list, coord)
        end
    end
    return coord_list
end
