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

    """
    Initalise a Basic Channel with unit costs
    """
    function BasicChannel(src::Int64, dest::Int64)
        newChannel = new(src, dest, Costs(1.0, 1.0), 1, true)
        return newChannel
    end

    """
    Initialise a BasicChannel with generic costs
    """
    function BasicChannel(src::Int64, dest::Int64, costs::Costs)
        tmpchannel = new(src, dest, costs, 1, true)
        return tmpchannel
    end
end

"""
Cartesian distance between two nodes
"""
function distance(src::QNode, dest::QNode)::Float64
    v = src.location
    w = dest.location
    return sqrt((v.x - w.x)^2 + (v.y - w.y)^2 + (v.z - w.z)^2)
end

"""
Calculate costs for FibreChannel given length
"""
function fibreCosts(length::Float64)::Costs
    β = 0.001
    # TODO: Go over these costs
    dE = P_to_dB(exp(-β * length))
    dF = Z_to_dB((1 + exp(-β * length))/2)
    return Costs(dE, dF)
end

"""
Calculate costs for AirChannel given length
"""
function airCosts(channel::AirChannel)::Costs
    """
    Line integral for effective density

    / L'
    |     rho(x * sin(theta)) dx
    / 0
    """

    srcCoords = channel.src.location
    destCoords = channel.dest.location
    L = channel.length
    # sin(theta)
    sinT = abs(srcCoords.z - destCoords.z)/L
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

    """
    Initialise a FibreChannel with specified length
    """
    function FibreChannel(src::Int64, dest::Int64, length::Float64)
        costs = fibreCosts(length)
        newChannel = new(src, dest, length, costs, 1, true)
        return tmpchannel
    end

    """
    Initialise FibreChannel infering length from node positions
    """
    function FibreChannel(src::Int64, dest::Int64)
        length = distance(src, dst)
        costs = fibreCosts(length)
        newChannel = new(src, dest, length, costs, 1, true)
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

    """
    Initialise a FibreChannel with specified length
    """
    function AirChannel(src::Int64, dest::Int64, length::Float64)
        costs = airCosts(length)
        newChannel = new(src, dest, length, costs, 1, true)
        return tmpchannel
    end

    function AirChannel(src::QNode, dest::QNode)
        length = distance(src, dst)
        costs = airCosts(length)
        newChannel = new(src, dest, length, costs, 1, true)
        return newChannel
    end
end

# TODO:
function update(channel::AirChannel, old_time::Float64, new_time::Float64)
    channel.length = distance(channel.src, channel.dest)
    channel.costs = cost(channel)
end


"""
Add a channel to the network
"""
function add(network::QNetwork, channel::QChannel)
    push!(network.channels, channel)
end
