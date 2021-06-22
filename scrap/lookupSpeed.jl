"""
Test to see if looking up entries in a bitArray is faster than looking
up entries in a vector of structs. Remarkably the bitArray is about
twice as slow!

use
@time lookup(<bitArray/fooArray>)
"""

using Random

struct Foo
    a::String
    b::String
    c::String
end

# Build array of bits
N = 10^8
bitArray = bitrand(N)

# Build array of Foo (Some nothing, some not)
fooArray = []
for bit in bitArray
    if bit == true
        push!(fooArray, Foo("apple", "banana", "cherry"))
    else
        push!(fooArray, nothing)
    end
end

function lookup(arr)
    idx = trunc(Int, N)
    return arr[idx]
end

# Performance is quite bad here
# 12.458597 seconds (100.06 M allocations: 3.115 GiB, 55.99% gc time)
# 100000000-element Array{Any,1}:
# How to improve?
function trueFalseMap(fooArray)
    bitArray = []
    map(fooArray) do x
        if x == nothing
            push!(bitArray, false)
        else
            push!(bitArray, true)
        end
    end
    return bitArray
end

# Julia performance tips suggests preallocating an array
# https://docs.julialang.org/en/v1/manual/performance-tips/

#Much better! 2.62 seconds for same result! Around 4-6x faster
newBitArray = BitArray(undef, N)
function preAllocTrueFalseMap(fooArray, bitArray)
    for (idx, foo) in enumerate(fooArray)
        if foo != nothing
            bitArray[idx] = true
        end
    end
end
