using QuNet
using Test
using LightGraphs
using SimpleWeightedGraphs

# include_networks = ["barbell", "simple_network", "simple_satnet",
# "small_square", "shortest_path_test", "smalltemp", "greedy_test", "bridge"]

# for N in include_networks
#     include("network-library/$N.jl")
# end

@testset "Network.jl" begin
    # Test BasicNetwork initialisation
    B = BasicNetwork()
    @test B.nodes == [] && typeof(B.nodes) == Array{QNode, 1}
    @test B.channels == [] && typeof(B.channels) == Array{QChannel, 1}
    @test B.diagAdj == [] && typeof(B.diagAdj) == BitArray{1}

    # Test BasicNetwork initialisation with QNodes
    C = BasicNetwork(10)
    @test length(C.nodes) == 10
    @test all(typeof(n) == BasicNode for n in C.nodes)
    # Check that id is properly initialised
    @test all(n.id == idx for (idx, n) in enumerate(C.nodes))

    # Test AddNode works on previous network
    addNode(C, 10)
    @test length(C.nodes) == 20
    @test all(typeof(n) == BasicNode for n in C.nodes)
    # Check that id is still initialised right
    @test all(n.id == idx for (idx, n) in enumerate(C.nodes))

    #
    # # Test: Channels are correctly added
    # @test length(barbell.channels) == 1
    #
    # # Test: getnode works for id
    # newnode = QuNet.getnode(barbell, 1)
    # @test newnode == barbell.nodes[1]
    #
    # # Test: getnode works for name
    # newnode = QuNet.getnode(barbell, "A")
    # @test newnode == barbell.nodes[1]
    #
    # # Test: getchannel works for id
    # newchannel = QuNet.getchannel(barbell, 1, 2)
    # @test newchannel == barbell.channels[1]
    #
    # # Test: getchannel works for string
    # newerchannel = QuNet.getchannel(barbell, "A", "B")
    # @test newerchannel == barbell.channels[1]
    #
    # # Test: Update a sat network and check that the costs have changed
    # AS = QuNet.getchannel(simple_satnet, "A", "S")
    # old_costs = AS.costs
    # update(simple_satnet)
    # new_costs = AS.costs
    # for key in keys(old_costs)
    #     @test old_costs[key] != new_costs[key]
    # end
    #
    # # Test: Reset the network back to t=0 and check position goes back to init.
    # S = QuNet.getnode(simple_satnet, "S")
    # update(simple_satnet, 0.0)
    # @test S.location.x == 500
    #
    # # Test: Check that deepcopy can clone network structure
    # Q = deepcopy(barbell)
    # @test all(Q.nodes[i] != barbell.nodes[i] for i in 1:length(Q.nodes))
    # @test cmp(string(Q), string(barbell)) == 0
    #
    # # Test: refresh_graph! creates SimpleWeightedGraph copies of Network for all costs
    # Q = deepcopy(barbell)
    # QuNet.refresh_graph!(Q)
    # @test length(Q.graph) == length(zero_costvector())
    # g = Q.graph["Z"]
    # @test nv(g) == 2
    # @test ne(g) == 2
    # @test g.weights[1, 2] == 0.5
    # @test g.weights[2, 1] == 0.5
    #
    # # Test refresh_graph! on satellite network
    # Q = deepcopy(simple_satnet)
    # QuNet.refresh_graph!(Q)
    # g = Q.graph["loss"]
    # @test nv(g) == 3
    # @test ne(g) == 4
    #
    # # Test 12: Test that update works on copied graph
    # Q = deepcopy(barbell)
    # update(Q)
    # @test cmp(string(Q), string(barbell)) != 0
    #
    # # Test 13 / 14: Test that getchannel fetches the right channel in
    # # a copied graph
    # Q = deepcopy(barbell)
    # AB = QuNet.getchannel(barbell, "A", "B")
    # CAB = QuNet.getchannel(Q, "A", "B")
    # @test (AB in barbell.channels) && (CAB in Q.channels)
    # @test !(CAB in barbell.channels) && !(AB in Q.channels)
end
