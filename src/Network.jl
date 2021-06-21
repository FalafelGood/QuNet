"""
Define main structures for Basic and Dynamic QNetworks
"""

"""

"""
mutable struct BasicNetwork <: QNetwork
    nodes::Array{QNode}
    channels::Array{QChannel}
    # Bit array representing lower diagonal adjacency matrix
    """
    4 vertex example:
    (src, dst) == (row, column)
    src < dst

         1 2 3 4
    1   |X 1 2 4|
    2   |X X 3 5|
    3   |X X X 6|
    4   |X X X X|
    """
    diagAdj::BitArray{1}
    time::Float64

    function BasicNetwork()
        newNet = new([], [], BitArray(undef, 0), 0)
        return newNet
    end

    function BasicNetwork(numNodes::Int64)
        newNodes::Array{QNode} = []
        for id in 1:numNodes
            node = BasicNode(id)
            push!(newNodes, node)
        end
        newNet = new(newNodes, [], BitArray(undef, numNodes), 0)
        return newNet
    end
end

"""
Add one or more nodes to the network
"""
function addNode(net::QNetwork, numNodes::Int64)
    # Make and add new nodes to net.list
    curNum = length(net.nodes)
    newNodes::Array{QNode} = []
    for id in curNum + 1 : curNum + numNodes
        node = BasicNode(id)
        push!(newNodes, node)
    end
    net.nodes = vcat(net.nodes, newNodes)
    # Update adjacency matrix
    newBits = BitArray(undef, numNodes)
    net.diagAdj = vcat(net.diagAdj, newBits)
end

"""
Get the index of diagAdj corresponding to a channel between src and dst.
Throws an error if either src or dst are larger than number of nodes in network
"""
function diagIdx(net::QNetwork, src::Int64, dst::Int64)::Int64
    if max(src, dst) > length(net.nodes)
        @assert false "Node selection is out of bounds"
    elseif src == dst
        return false
    elseif src > dst
        tmp = src; src = dst; dst = tmp
    end
    idx = 1/2 * (dst - 1) * dst - (dst-src-1)
    return idx
end

"""
Is there a channel between src and dst?
Throws an error if either src or dst are larger than number of nodes in network
"""
function hasChannel(net::QNetwork, src::Int64, dst::Int64)::Bool
    idx = diagIdx(net, src, dst)
    return net.diagAdj[idx]
end

"""
Get the index of a channel between src and dst in the net.channels array.
If no channel exists between src and dst, returns nothing
"""
function channelIdx(net::QNetwork, src::Int64, dst::Int64)
    # The index of diagAdj would be the same as channelIdx if it were a clique
    idx = diagIdx(net, src, dst)
    # If no channel exists, return nothing
    if net.diagAdj[idx] == false
        return nothing
    end
    truIdx = sum[net.diagAdj[1:idxClique]]
    return idx
end

"""
Fetch the channel between src and dst
If no such channel exists, return nothing
"""
function getChannel(net::QNetwork, src::Int64, dst::Int64)
    idx = channelIdx(net, src, dst)
    if idx == nothing
        return nothing
    end
    return net.channels[idx]
end

function addChannel(net::QNetwork, src::Int64, dst::Int64)
    # TODO
    # If channel already exists, return nothing
    idx = diagIdx(net, src, dst)
    if net.diagAdj[idx] == true
        return nothing
    end
    newChannel = BasicChannel(src, dst)
    # The index to insert in net.channels: The +1 sum of all previous entries
    # Example: b = [0, 1, 1, {0}, 1, 0, 1], 4th entry selected to add
    # This will be inserted into the third index of net.channels
    truIdx = sum(net.diagAdj[1:idxClique]) + 1
    insert!(net.channels, truIdx, newChannel)
end

# TODO: IO with other graph frameworks

"""
    refresh_graph!(network::QNetwork)

Converts a QNetwork into several weighted LightGraphs (one
graph for each associated cost), then updates the QNetwork.graph attribute
with these new graphs.
"""
function refresh_graph!(network::QNetwork)

    refreshed_graphs = Dict{String, SimpleWeightedDiGraph}()

    for cost_key in keys(zero_costvector())
        refreshed_graphs[cost_key] = SimpleWeightedDiGraph()

        # Vertices
        add_vertices!(refreshed_graphs[cost_key], length(network.nodes))

        # Channels
        for channel in network.channels
            if channel.active == true
                src = findfirst(x -> x == channel.src, network.nodes)
                dest = findfirst(x -> x == channel.dest, network.nodes)
                weight = channel.costs[cost_key]
                add_edge!(refreshed_graphs[cost_key], src, dest, weight)
                add_edge!(refreshed_graphs[cost_key], dest, src, weight)
            end
        end
    end
    network.graph = refreshed_graphs
end

"""
    GridNetwork(dim::Int64, dimY::Int64)

Generates an X by Y grid network.
"""
function GridNetwork(dimX::Int64, dimY::Int64; edge_costs::Dict = unit_costvector())
    graph = LightGraphs.grid([dimX,dimY])
    net = QNetwork(graph; edge_costs=edge_costs)

    for x in 1:dimX
        for y in 1:dimY
            this = x + (y-1)*dimX
            net.nodes[this].location = Coords(x,y)
        end
    end

    refresh_graph!(net)
    return net
end

"""
```function update(network::QNetwork, new_time::Float64)```

The `update` function iterates through all objects in the network and updates
them according to a new global time.
"""
function update(network::QNetwork, new_time::Float64)
    old_time = network.time
    for node in network.nodes
        update(node, old_time, new_time)
    end

    for channel in network.channels
        update(channel, old_time, new_time)
    end
    network.time = new_time
end

"""
```function update(network::QNetwork)```

This instance of update iterates through all objects in the network and updates
them by the global time increment TIME_STEP defined in QuNet.jl
"""
function update(network::QNetwork)
    old_time = network.time
    new_time = old_time + TIME_STEP
    for node in network.nodes
        update(node, old_time, new_time)
    end

    for channel in network.channels
        update(channel, old_time, new_time)
    end
    network.time = new_time
end


"""
    getnode(network::QNetwork, id::Int64)

Fetch the node object corresponding to the given ID / Name
"""
function getnode(network::QNetwork, id::Int64)
    return network.nodes[id]
end


function getnode(network::QNetwork, name::String)
    for node in network.nodes
        if node.name == name
            return node
        end
    end
end

function getchannel(network::QNetwork, src::Union{Int64, String},
    dst::Union{Int64, String})
    src = getnode(network, src)
    dst = getnode(network, dst)
    for channel in network.channels
        if channel.src == src && channel.dest == dst
            return channel
        end
    end
end

"""
function add_qnode!(network::QNetwork; nodename::String="", nodetype::DataType=BasicNode)
    @assert nodetype in subtypes(QNode)
    new_node = nodetype(nodename)
    add(network, new_node)
end
"""

"""
function add_channel!(network::QNetwork, src::Union{Int64, String},
    dst::Union{Int64, String};
    name::string="", type=BasicChannel)
    src = getnode(src)
    dst = getnode(dst)
    @assert type in [BasicChannel, AirChannel]
    new_channel = type(name, src, dst)
    add(network, new_channel)
end
"""
