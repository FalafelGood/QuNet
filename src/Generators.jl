"""
GridNetwork(dim::Int64, dimY::Int64)

Generates an X by Y grid network.
"""
function GridNetwork(dimX::Int64, dimY::Int64; edge_costs::Dict = unit_costvector())
    graph = LightGraphs.grid([dimX,dimY])
    net = QNetwork(graph; edge_costs=edge_costs)

    for x in 1:dimX
        for y in 1:dimY
            this = x + (y-1)*dimX
            net.nodes[this].location = Coords(x,y)
        end
    end

    refresh_graph!(net)
    return net
end
