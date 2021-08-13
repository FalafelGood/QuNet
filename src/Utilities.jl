"""
Primative methods for network reductions (For example purifications and swaps)
"""

"""
Calculate the purification costs given a Pathset
"""
function purifyCosts(graph::MetaDiGraph, pathset::Pathset)::Costs

    """
    Rather than push path costs multiple times, this function calculates
    purification costs for a given path based on how many times in appears
    in the Pathset
    """
    function purifyPathMultipleTimes(pathCosts, freq)
        dE = pathCosts.dE
        dF = pathCosts.dF
        E = dE_to_E(dE)
        F = dF_to_F(dF)
        pur_E = E^freq * (F^freq + (1 .- F)^freq)
        pur_F = F^freq / (F^freq + (1 .- F)^freq)
        return Costs(pur_E, pur_F)
    end

    # Get costs for each path in pathset
    pathCosts = []
    for (idx, path) in enumerate(pathset.paths)
        # TODO: Won't work yet because g_pathCosts uses LightGraph Edges
        pcosts = g_pathCosts(graph, path)
        purifyPathMultipleTimes(pcosts, pathset.freqs[idx])
        push!(pathCosts, pcosts)
    end

    dE = collect(cost.dE for cost in pathCosts)
    dF = collect(cost.dF for cost in pathCosts)
    E = dE_to_E.(dE)
    F = dF_to_F.(dF)
    pur_E = prod(E) * (prod(F) + prod(1 .- F))
    pur_F = prod(F) / (prod(F) + (prod(1 .- F)))
    dpur_E = E_to_dE(pur_E)
    dpur_F = F_to_dF(pur_F)
    return Costs(dpur_E, dpur_F)
end

"""
Reduce the graph associated with the QuNetwork by performing a purification
over a pathset
"""
function purify(mdg::MetaDiGraph, pathset::Pathset; addChannel = false)
    purCosts = purifyCosts(mdg, pathset)
    remPathset(mdg, pathset)
    if addChannel == true
        addPurifyChannel(mdg, pathset)
    end
    return purCosts
end

"""
After purification, this function adds a channel between the src and dst with
the purified costs and information about the Pathset.
"""
function addPurifyChannel(mdg::MetaDiGraph, pathset::Pathset, purCosts::Costs)
    # Add a channel to the network
    purChannel = PurifiedChannel(pathset.src, pathset.dst, purCosts, pathset)
    c_addQChannel(mdg, purChannel)
end

# function purify_PBS(F1::Float64,F2::Float64)::(Float64,Float64)
#     F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
#     P = 1
#     return (F,P)
# end
#
#
# function purify_CNOT(F1::Float64,F2::Float64)::(Float64,Float64)
#     F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
#     P = 1
#     return (F,P)
# end
