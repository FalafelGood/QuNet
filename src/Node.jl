"""
Class definitions for QNode objects
"""

"""
The default QNode object. Nothing special, but nothing unspecial either ;-)"
"""
mutable struct BasicNode <: StaticNode
    # Basic parameters
    qid::Int64
    active::Bool
    has_memory::Bool

    function BasicNode(qid::Int64)
        newNode = new(qid, true, false)
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
"""
mutable struct CartNode <: StaticNode
    qid::Int64
    active::Bool
    has_memory::Bool
    coords::CartCoords

    function CartNode(qid::Int64, coords::CartCoords)
        newNode = new(qid, true, false, coords)
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
mutable struct CartSatNode <: DynamicNode
    qid::Int64
    active::Bool
    has_memory::Bool
    coords::CartCoords
    velocity::CartVelocity
    time::Float64
    update!::Function

    """
    update method for the CartSatNode type.
    """
    function update!(sat::CartSatNode, dt::Float64)
        # Calculate new position from velocity
        sat.location.x += sat.velocity.x * dt
        sat.location.y += sat.velocity.y * dt
        sat.location.z += sat.velocity.z * dt
        sat.time += dt
        return
    end

    function CartSatNode(qid::Int64, coords::CartCoords, velocity::CartVelocity)
        newNode = new(qid, true, false, coords, velocity, 0.0, update!)
        return newNode
    end
end
