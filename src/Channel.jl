"""
Define channel types for BasicChannel, FibreChannel, and AirChannel.
Define methods for determining costs of latter two.
"""

"""
Default Channel type
"""
mutable struct BasicChannel <: QChannel
    src::Int64
    dst::Int64
    costs::Costs
    capacity::Int64
    active::Bool
    directed::Bool

    """
    Initalise a Basic Channel with unit costs
    """
    function BasicChannel(src::Int, dst::Int)
        newChannel = new(src, dst, Costs(0.0, 0.0), 1, true, false)
        return newChannel
    end

    """
    Initialise a BasicChannel with generic costs
    """
    function BasicChannel(src::Int, dst::Int, costs::Costs)
        tmpchannel = new(src, dst, costs, 1, true, false)
        return tmpchannel
    end
end

"""
Cartesian distance between two nodes
"""
function cartDistance(src::QNode, dst::QNode)::Float64
    v = src.coords
    w = dst.coords
    return sqrt((v.x - w.x)^2 + (v.y - w.y)^2 + (v.z - w.z)^2)
end

"""
Calculate costs for FibreChannel given length
Length and attenuation parameter β have unspecified units.
"""
function fibreCosts(length::AbstractFloat, β::AbstractFloat = 0.001)::Costs
    # TODO: Come up with more realistic fibre cost model and parameters
    # ATM this model means dE and dF are the same. Not likely!
    dE = E_to_dE(exp(-β * length))
    dF = F_to_dF((1 + exp(-β * length))/2)
    return Costs(dE, dF)
end

"""
Fibre optic channel, where the cost is determined by exponential loss in length
"""
mutable struct FibreChannel <: QChannel
    src::Int64
    dst::Int64
    length::Float64
    costs::Costs
    capacity::Int64
    active::Bool
    directed::Bool

    """
    Initialise a FibreChannel with specified length
    """
    function FibreChannel(src::Int, dst::Int, length::AbstractFloat)
        costs = fibreCosts(length)
        newChannel = new(src, dst, length, costs, 1, true, false)
        return newChannel
    end

    """
    Initialise FibreChannel infering length from node positions
    """
    function FibreChannel(src::QNode, dst::QNode)
        length = cartDistance(src, dst)
        costs = fibreCosts(length)
        newChannel = new(src.id, dst.id, length, costs, 1, true, false)
        return newChannel
    end
end

mutable struct AirChannel <: QChannel
    src::Int64
    dst::Int64
    length::Float64
    costs::Costs
    capacity::Int64
    active::Bool
    directed::Bool

    """
    Initialise an AirChannel from QNodes
    """
    function AirChannel(src::QNode, dst::QNode)
        length = cartDistance(src, dst)
        costs = QuNet.airCosts(src, dst)
        newChannel = new(src.id, dst.id, length, costs, 1, true, false)
        return newChannel
    end
end

"""
Calculate costs for AirChannel given length
"""
function airCosts(src::QNode, dst::QNode)::Costs
    """
    Line integral for effective density

    / L'
    |     rho(x * sin(theta)) dx
    / 0
    """

    L = cartDistance(src, dst)
    # sin(theta)
    sinT = abs(src.coords.z - dst.coords.z)/L
    # atmosphere function
    ρ = expatmosphere
    f(x) = ρ(x*sinT)
    # Effective atmospheric depth
    d = quadgk(f, 0, L)[1]

    # Constants
    β = 10e-5
    d₀ = 10e7

    E = exp(-β*d)*(d₀)^2/(d + d₀)^2
    F = (1+exp(-β*d))/2

    # Calculate decibelic forms of efficiency and fidelity
    dE = E_to_dE(E)
    dF = F_to_dF(F)
    return Costs(dE, dF)
end

# TODO: Test me
function update(channel::AirChannel, old_time::Float64, new_time::Float64)
    channel.length = distance(channel.src, channel.dst)
    channel.costs = cost(channel)
end

# """
# Add a channel to the network
# """
# function add(network::QNetwork, channel::QChannel)
#     push!(network.channels, channel)
# end
