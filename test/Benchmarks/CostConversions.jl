"""
Benchmark cost conversion functions, specifically checking
to see if devectorisation is faster.
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
    return dE
end
