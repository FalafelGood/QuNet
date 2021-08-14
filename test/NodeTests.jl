using QuNet
using Test

@testset "Node.jl" begin
    # Test Basic node is initalised correctly
    B = BasicNode(1)
    @test (B.qid == 1 && B.active == true)

    # Test CartNode initialisation
    C = CartNode(1, CartCoords(1.0, 2.0, 3.0))
    @test (C.qid == 1 && C.active == true
    && C.coords.x == 1.0 && C.coords.y == 2.0 && C.coords.z == 3.0)

    # Test CartSatNode init
    S = CartSatNode(1, CartCoords(1.0, 2.0, 3.0), CartVelocity(1.0, 2.0, 3.0))
    @test (S.qid == 1 && S.active == true
    && S.coords.x == 1.0 && S.coords.y == 2.0 && S.coords.z == 3.0
    && S.velocity.x == 1.0 && S.velocity.y == 2.0 && S.velocity.z == 3.0)
end
