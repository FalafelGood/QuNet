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
    return Costs(pur_E, pur_F)
end

"""
Reduce the graph associated with the QuNetwork by performing a purification
over a pathset
"""
function purify(net::BasicNetwork, pathset::Pathset; addChannel = false)
    purCosts = purifyCosts(net.graph, pathset)
    remPathset(net, pathset)
    if addChannel == true
        addPurifyChannel(net, pathset)
    end
    return purCosts
end

"""
After purification, this function adds a channel between the src and dst with
the purified costs and information about the Pathset.

Strictly speaking this is an edge-vertex-edge. The reason we implement it this
way is two-fold. First, consider purification between two adjacent nodes.
Simple graphs like MetaDiGraphs can't allow for multiple edges between the same
two nodes. Secondly, and more subtly, having a designated purification channel
allows us to have multiple purification sets between a given end-user pair.
This could be useful in testing protocols in which we iterate through multiple
purification rounds.
"""
function addPurifyChannel(net::BasicNetwork, pathset::Pathset)
    # TODO
    """
    Unpack costs into a vertex. (Recycled code from NetConversion.jl)
    """
    function unpackCosts(mdg, unpackTo::Int, costs)::Nothing
        typeName = string(typeof(costs))
        for fieldType in fieldnames(typeof(costs))
            propVal = getproperty(costs, fieldType)
            # make new symbol by concatanating strings
            newField = typeName * "Δ" * string(fieldType)
            set_prop!(mdg, unpackTo, Symbol(newField), propVal)
        end
        # has_prop(:pathset) makes isPurified redundant, but included anyways for niceness.
        vprops = Dict(:isPurified => true :pathset => pathset)
        middle = g_addVertex!(mdg, vprops)

        # TODO: Write BasicChannel then convert it to whatever edge + metadata
        # we need.
        g_addEdge!(mdg, pathset.src, middle)
        g_addEdge!(mdg, middle, pathset.src)
        g_addEdge!(mdg, middle, pathset.dst)
        g_addEdge!(mdg, pathset.dst, middle)
    end
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
