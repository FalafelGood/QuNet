using QuNet
using Test
using LightGraphs
using SimpleWeightedGraphs

@testset "Node.jl" begin
    # Test Basic node is initalised correctly
    B = BasicNode(1)
    @test (B.id == 1 && B.costs.dE == 0.0 && B.costs.dE == 0.0 && B.active == true && B.time == 0)

    # Test Basic node initialisation for custom costs
    myCosts = Costs(1.1, 2.2)
    C = BasicNode(1, myCosts)
    @test (C.costs.dE == 1.1 && C.costs.dF == 2.2)

    # # Test node properties can be updated
    # B = BasicNode("B")
    # B.location = Coords(100, 0, 0)
    # @test isequal(B.location.x, 100)
    #
    # # Test PlanSatNode is initialised
    # S = PlanSatNode("S")
    # S.location = Coords(0, 0, 1000)
    # S.velocity = Velocity(1000, 0, 0)
end
