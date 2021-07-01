"""
The default QNode object. Nothing special, but nothing unspecial either ;-)"
"""
mutable struct BasicNode <: QNode
    # Basic parameters
    id::Int64
    costs::Costs
    active::Bool
    has_memory::Bool
    # Timestep for temporal metagraphs
    time::Int64

    function BasicNode(id::Int64)
        newNode = new(id, Costs(0.0, 0.0), true, false, 0)
        return newNode
    end

    function BasicNode(id::Int64, costs::Costs)
        newNode = new(id, costs, true, false, 0)
        return newNode
    end
end

"""
Coordinates of the QNode object in up to three spatial dimensions
"""
mutable struct CartCoords
    x::AbstractFloat
    y::AbstractFloat
    z::AbstractFloat

    CartCoords() = new(0.0,0.0,0.0)
    CartCoords(x,y) = new(x,y,0.0)
    CartCoords(x,y,z) = new(x,y,z)
end

"""
Similar to BasicNode, but with an extra parameter for cartesian spatial coordinates
and a continuous time parameter as opposed to discrete time
"""
mutable struct CartNode <: QNode
    id::Int64
    costs::Costs
    active::Bool
    has_memory::Bool
    coords::CartCoords
    time::Float64

    function CartNode(id::Int64, coords::CartCoords)
        newNode = new(id, Costs(0.0, 0.0), true, false, coords, 0.0)
        return newNode
    end

    function CartNode(id::Int64, costs::Costs, coords::CartCoords)
        newNode = new(id, costs, true, false, coords, 0.0)
        return newNode
    end
end

"""
Cartesian Velocity in up to 3 spatial coordinates
"""
mutable struct CartVelocity
    x::AbstractFloat
    y::AbstractFloat
    z::AbstractFloat

    CartVelocity() = new(0.0,0.0,0.0)
    CartVelocity(x,y) = new(x,y,0.0)
    CartVelocity(x,y,z) = new(x,y,z)
end

"""
Satellite Node in Cartesian Coordinates
"""
mutable struct CartSatNode <: QNode
    id::Int64
    costs::Costs
    active::Bool
    has_memory::Bool
    coords::CartCoords
    velocity::CartVelocity
    time::Float64

    function CartSatNode(id::Int64, coords::CartCoords, velocity::CartVelocity)
        newNode = new(id, Costs(0.0, 0.0), true, false, coords, velocity, 0.0)
        return newNode
    end
end


"""
Update the position of a planar satellite node by incrementing its current
location with the distance covered by its velocity in "TIME_STEP" seconds.
"""
function update(sat::CartSatNode, old_time::Float64, new_time::Float64)
    # Calculate new position from velocity
    sat.location.x += sat.velocity.x * (new_time - old_time)
    sat.location.y += sat.velocity.y * (new_time - old_time)
    sat.location.z += sat.velocity.z * (new_time - old_time)
    return
end

# """
# Add a QNode object to the network.
#
# Example:
#
# ```
# using QuNet
# Q = QNetwork()
# A = BasicNode("A")
# add(Q, A)
# ```
# """
# function add(network::QNetwork, node::QNode)
#     push!(network.nodes, node)
#     node.id = length(network.nodes)
# end
#
# """
# Remove a Qnode object from the network.
#
# The convention for node removal in QuNet echos that of LightGraphs.jl.
# Suppose a given network has N nodes, and we want to remove the node with the
# id v:
#
# 1. Check if v < N . If false, simply pop the node from QNetwork.nodes
# 2. Else, swap the nodes v and N, then pop from QNetworks.nodes
# """
# function remove(network::QNetwork, node::QNode)
#     node_id = node.id
#     if node_id != length(network.nodes)
#         # Swap the node to be removed with the last node
#         # (Same removal strategy as SimpleGraphs)
#         tmp_node = deepcopy(node)
#         N = last(network.nodes)
#         node = N
#         node.id = node_id
#         N = tmp_node
#     end
#     pop!(network.nodes)
# end
#
# """
# ```function update(node::QNode)```
#
# Does nothing
# """
# function update(node::QNode)
# end
#
# function update(node::QNode, old_time::Float64, new_time::Float64)
# end
#
#
# # Identical structure to Coords, but using a different name for distrinction
