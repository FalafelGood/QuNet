using QuNet
using Test

@testset "Channel.jl" begin
    # Test Basic channel is initalised correctly
    B = BasicChannel(1, 2)
    @test (B.src == 1 && B.dst == 2 && B.costs.dE == 1.0 && B.costs.dF == 1.0)

    # Test cartesian distance
    A = CartNode(1, CartCoords())
    B = CartNode(2, CartCoords(3.0, 4.0))
    @test (5 == QuNet.cartDistance(A, B))

    # TODO: Test fibreCosts

    # Test FibreChannel init
    C = FibreChannel(1, 2, 100.0)
    @test (C.src == 1 && C.dst == 2)

    C = FibreChannel(A, B)
    @test (C.src == 1 && C.dst == 2)

    # TODO: Test AirChannel costs

    # Test AirChannel init
    C = AirChannel(A, B)
    @test (C.src == 1 && C.dst == 2)

end
