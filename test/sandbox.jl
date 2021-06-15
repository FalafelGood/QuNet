using QuNet

function make_user_pairs_wbuffer(squarenet::QNetwork, num_pairs::Int; buffer::Int=1)::Vector{Tuple{Int64, Int64}}
    num_nodes = length(squarenet.nodes)
    d = sqrt(num_nodes)
    @assert isinteger(d) "Grid network is not square"
    @assert buffer > 0
    @assert d - 2 * buffer > 1 "Gridsize too small for given buffer"
    rand_space = Array(collect(0:num_nodes-1))
    # Filter out nodes in the margin
    # NOTE Cool trick: n % d == x coord, n ÷ d == y coord
    filter!(i -> (buffer <= (i%d)) && (buffer <= (i÷d)) && (i%d < d-buffer) && (i÷d < d-buffer), rand_space)
    # Set first index to 1
    rand_space .+= 1
    pairs = make_user_pairs(squarenet, num_pairs, node_list=rand_space)
    return pairs
end

G = GridNetwork(5, 5)
p = make_user_pairs_wbuffer(G, 3, buffer = 1)
println(p)
