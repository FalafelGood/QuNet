using QuNet
using Test

@testset "Conversions.jl" begin
    # Test toLightGraph
    net = BasicNetwork(3)
    addChannel(net, 1, 2)
    addChannel(net, 2, 3)
    addChannel(net, 3, 1)
    println(net)
end
