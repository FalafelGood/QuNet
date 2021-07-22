"""
Master test set for QuNet.
"""

using QuNet
using Test

const testdir = dirname(@__FILE__)

tests = ["ChannelTests",
        "NetInterfaceTests",
        "NetworkTests",
        "NodeTests",
        "PathsetTests",
        ]

@testset "QuNet" begin
    for t in tests
        tp = joinpath(testdir, "$(t).jl")
        include(tp)
    end
end
