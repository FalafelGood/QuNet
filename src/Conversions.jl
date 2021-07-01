"""
Functions for converting QNetwork objects into more optimised graph types.
These functions integrate with the master function convertNet!() in Network.jl
"""

"""
Convert a QNetwork object to directed MetaGraphs in Julia LightGraphs.
(One MetaGraph for each channel cost) Directed MetaGraphs are used over weighted
di-graphs is because they are more performant at removing edges.
"""
function toLightGraph(net::BasicNetwork)::Vector{AbstractGraph}

    mdg = MetaDiGraph(net.numNodes)

    for channel in net.channels
        src = channel.src; dst = channel.dst
        add_edge!(mdg, src, dst)
        add_edge!(mdg, dst, src)
        for fieldType in fieldnames(channel)
            # TODO: Naive implementation
            set_prop!(mdg, Edge(src, dst), fieldType = channel.fieldType)
        end
    end
    return mdg
end


# for costType in fieldnames(Costs)
#     add_edge!(mdg, src, dst)
#     set_prop!(mdg, Edge(src, dst), ::costType = channel.cost.costType)
#     add_edge!(mdg, dst, src)
#     set_prop!(mdg, Edge(dst, src), ::costType = channel.cost.costType)
#  end


# Change in graph library -> No change in QuNet code.

# """
# ncpath (node cost path) is an attribute of all nodes in the LightGraphs
# implementation of the network. If a node has costs, this function splits
# the node in two; A "sink" and "source" with a directed edge between them.
# Undirected channels that connect the node will also be decomposed outside
# function -- An incoming edge to the sink, an outgoing edge from the source.
#
# ncpath == 0:
#     Node has no cost, no cost path exists
# ncpath > 0:
#     ncpath points forward to the source node with idx ncpath
# ncpath < 0:
#     ncpath points backward to sink node --
# """
# function make_ncpath(mdg::MetaDiGraph, node::QNode)::Nothing
#     add_vertex!(mdg)
#     newNode = mdg.nv
#     add_edge!(mdg, node.id, newNode)
#     set_prop!(mdg, Edge(mdg, node.id), node.costs)
#     set_prop!(mdg, node.id, ::ncpath = newNode)
#     set_prop!(mdg, newNode, ::ncpath = -node.id)
# end

# for node in net.nodes
#     # If any nodes have cost, employ intermediate edge with node costs
#     if node.costs != zeroCost
#         make_ncpath(mdg, node)
#     else
#         # no cost path exists
#         set_props!(mdg, node, ::ncpath = 0)
#     end
