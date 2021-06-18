"""
Utilities.jl contains conversion methods, purification schemes,
and other miscelanious utilities
"""


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
    return dB
end

"""
Convert from dephasing probability to decibelic form
"""
function F_to_dF(F::Float64)::Float64
    dF = -10.0*log(10, 2*F-1)
    return dF
end

"""
Convert from decibelic dephasing to metric form
"""
function dF_to_F(dF::Float64)::Float64
    F = (10^(-dF/10) + 1)/2
    return F
end


function purify_PBS(F1::Float64,F2::Float64)::(Float64,Float64)
    F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
    P = 1
    return (F,P)
end


function purify_CNOT(F1::Float64,F2::Float64)::(Float64,Float64)
    F = F1*F1 / (F1*F2 + (1-F1)(1-F2))
    P = 1
    return (F,P)
end

"""
Probabilistic purification scheme used in greedy_multi_path!
Takes a list of cost vectors (dictionaries) as input and returns a cost vector
"""
function purify(cost_vectors::Vector{Dict{Any,Any}}, return_as_dB::Bool=true)
    @assert keys(zero_costvector()) == keys(cost_vectors[1]) "Incompatible keys"
    p_arr = [dB_to_P(i["loss"]) for i in cost_vectors]
    z_arr = [dB_to_Z(i["Z"]) for i in cost_vectors]

    p = prod(p_arr) * (prod(z_arr) + prod(1 .- z_arr))
    z = prod(z_arr) / ((prod(z_arr) + prod(1 .- z_arr)))

    if return_as_dB == true
        return Dict("loss"=>P_to_dB(p), "Z"=>Z_to_dB(z))
    else
        return Dict("loss"=>p, "Z"=>z)
    end
end


function purify(paths::Vector{<:QChannel}, return_as_dB::Bool=true)
    cost_vectors = Vector{Dict}()
    for path in paths
        cost = get_pathcv(path)
        push!(cost_vectors, cost)
    end
    purify(cost_vectors, return_as_dB)
end
