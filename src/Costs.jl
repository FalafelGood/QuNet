"""
Structure for Node and channel costs, and conversion methods between metric
and decibelic costs
"""

"""
Cost object for QNodes and QChannels
"""
@def_structequal mutable struct Costs
    dE::Float64
    dF::Float64

    function Costs()
        newCosts = new(0.0, 0.0)
        return newCosts
    end
end

function Costs(dE::Float64, dF::Float64)
    newCosts = Costs()
    newCosts.dE = dE
    newCosts.dF = dF
    return newCosts
end

"""
Convert from decibelic loss to metric form
"""
function dE_to_E(dE::Float64)::Float64
    E = 10.0^(-dE/10)
    return E
end

"""
Convert from metric form to decibelic loss
"""
function E_to_dE(E::Float64)::Float64
    dE = -10.0*log(10,E)
    return dE
end

"""
Convert from bell pair fidelity to decibelic form
"""
function F_to_dF(F::Float64)::Float64
    dF = -10.0*log(10, 2*F-1)
    return dF
end

"""
Convert from decibelic bell pair fidelity to metric form
"""
function dF_to_F(dF::Float64)::Float64
    F = (10^(-dF/10) + 1)/2
    return F
end

function halfCost(costs::Costs)
    newCosts = Costs()
    for costType in fieldnames(Costs)
        halfcost = getfield(costs, costType)/2
        setfield!(newCosts, costType, halfcost)
    end
    return newCosts
end
