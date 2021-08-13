using QuNet
using Test

@testset "Node.jl" begin
    # Test Basic node is initalised correctly
    B = BasicNode(1)
    @test (B.qid == 1 && B.costs.dE == 0.0 && B.costs.dE == 0.0 && B.active == true)

    # Test Basic node initialisation for custom costs
    myCosts = Costs(1.1, 2.2)
    C = BasicNode(1, myCosts)
    @test (C.costs.dE == 1.1 && C.costs.dF == 2.2)

    # Test CartNode initialisation
    C = CartNode(1, CartCoords(1.0, 2.0, 3.0))
    @test (C.qid == 1 && C.costs.dE == 0.0 && C.costs.dF == 0.0 && C.active == true
    && C.coords.x == 1.0 && C.coords.y == 2.0 && C.coords.z == 3.0)

    # Test CartNode init for custom costs
    C = CartNode(1, Costs(1.0, 2.0), CartCoords(1.0, 2.0, 3.0))
    @test (C.qid == 1 && C.costs.dE == 1.0 && C.costs.dF == 2.0 && C.active == true
    && C.coords.x == 1.0 && C.coords.y == 2.0 && C.coords.z == 3.0)

    # Test CartSatNode init
    S = CartSatNode(1, CartCoords(1.0, 2.0, 3.0), CartVelocity(1.0, 2.0, 3.0))
    @test (S.qid == 1 && S.costs.dE == 0.0 && S.costs.dF == 0.0 && S.active == true
    && S.coords.x == 1.0 && S.coords.y == 2.0 && S.coords.z == 3.0
    && S.velocity.x == 1.0 && S.velocity.y == 2.0 && S.velocity.z == 3.0)
end
