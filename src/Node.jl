"""
The default QNode object. Nothing special, but nothing unspecial either ;-)"
"""
mutable struct BasicNode <: StaticNode
    # Basic parameters
    id::Int64
    costs::Costs
    active::Bool
    has_memory::Bool

    function BasicNode(id::Int64)
        newNode = new(id, Costs(0.0, 0.0), true, false)
        return newNode
    end

    function BasicNode(id::Int64, costs::Costs)
        newNode = new(id, costs, true, false)
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
    id::Int64
    costs::Costs
    active::Bool
    has_memory::Bool
    coords::CartCoords

    function CartNode(id::Int64, coords::CartCoords)
        newNode = new(id, Costs(0.0, 0.0), true, false, coords)
        return newNode
    end

    function CartNode(id::Int64, costs::Costs, coords::CartCoords)
        newNode = new(id, costs, true, false, coords)
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
    id::Int64
    costs::Costs
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

    function CartSatNode(id::Int64, coords::CartCoords, velocity::CartVelocity)
        newNode = new(id, Costs(0.0, 0.0), true, false, coords, velocity, 0.0, update!)
        return newNode
    end
end
