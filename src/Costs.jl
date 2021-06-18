"""
Define structure for Node and channel costs
"""

mutable struct Costs
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
