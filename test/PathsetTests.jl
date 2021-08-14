using QuNet
using LightGraphs
using MetaGraphs
using Test

@testset "PathsetTests.jl" begin
    # Test that two identical path sets (but initialised in different orders)
    # -are equivalent to eachother.
    path1 = [(1,2), (2,3)]
    path2 = [(1,200), (200, 3)]
    path3 = [(1,2), (2,5), (5,3)]
    path4 = [(1,3)]
    ps1 = QuNet.Pathset([path1, path2, path3, path4])
    ps2 = QuNet.Pathset([path4, path3, path2, path1])
    @test ps1 == ps2

    # Test ReversePathset    
    rps1 = QuNet.reversePathset(ps1)
    @test rps1 != ps1
    rrps1 = QuNet.reversePathset(rps1)
    @test rrps1 == ps1
end
