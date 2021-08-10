using QuNet
using Test

@testset "CostsTests.jl" begin
    # Test halfCost
    onecost = Costs(1.,1.)
    halfcost = halfCost(onecost)
    @test halfcost == Costs(0.5, 0.5)
end
