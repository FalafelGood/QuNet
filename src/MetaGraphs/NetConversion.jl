"""
Functions for converting QNetwork objects into more optimised graph types.
These functions integrate with the master function convertNet!() in Network.jl
"""

"""
Unpack the attributes of a struct into attributes of a MetaDiGraph object

Properties of a MetaGraph can be anything, including structs.
Normally this wouldn't be an issue but setting the weights for
methods like a_star with MetaGraphs.weightfield!() requires a single
weight attribute to be set. This means that the fields of a struct
like "Costs" need to be individually unpacked into the MetaGraph properties

The naming convention for unpacked attributes is identical to the
'dot notation' but replaced with right arrow (→).

Example:
struct Foo
    bar
end

Foo.bar => :FooΔbar

# TODO: Make sure both channels are initialised.
"""
function unpackStruct(mdg, unpackTo::Union{Int, Edge}, structobj)::Nothing
    typeName = string(typeof(structobj))
    for fieldType in fieldnames(typeof(structobj))
        propVal = getproperty(structobj, fieldType)
        # make new symbol by concatanating strings
        newField = typeName * "Δ" * string(fieldType)
        set_prop!(mdg, unpackTo, Symbol(newField), propVal)
    end
end


"""
Set the attrtibutes of a vertex given a qnode and its index
"""
function setVertexAttrs(mdg, qnode, idx)
    set_prop!(mdg, idx, :type, typeof(qnode))
    qnodeFields = fieldnames(typeof(qnode))
    for fieldType in qnodeFields
        if fieldType != :costs
            propVal = getproperty(qnode, fieldType)
            set_prop!(mdg, idx, fieldType, propVal)
        end
    end
end

"""
Add a QNode to the Network graph


If a node has costs, this function splits the node in two; A "sink" and
"spout" with a directed edge between them. Undirected channels that
connect the node will also be split outside this function -- An incoming
edge to the sink, an outgoing edge from the spout -- both with the same
costs.

A node that passes through this method is given the attribute hasCost for node
cost, which is true if it has a cost and false otherwise. A node is a sink
(or has no cost) if its :qid is positive. If the id is negative, then it's a
spout that connects to the node with corresponding positive :qid.
"""
function c_addQNode!(mdg::MetaDiGraph, qnode::QNode, nodeCosts::Bool=false)
    # Add vertex to graph with default metaproperties
    v = g_addVertex!(mdg)
    # set vertex props to be qnode fields
    setVertexAttrs(mdg, qnode, v)
    mapNodeToVert(mdg, qnode.qid, v)
    if nodeCosts == true && qnode.costs != zeroCosts
        set_prop!(mdg, v, :hasCost, true)
        addCostNode!(mdg, v, qnode)
    end
end


"""
Add cost to Node in MetaDiGraph
"""
function addCostNode!(mdg, v, qnode)::Nothing
    # Add vertex to graph with default metaproperties
    cost_v = g_addVertex!(mdg)
    # Conncect directed edge between node and cost node
    q_addEdge!(mdg, v, cost_v)
    # Set properties for cost node
    setVertexAttrs(mdg, qnode, cost_v)
    set_prop!(mdg, cost_v, :qid, -inIdx)
    set_prop!(mdg, cost_v, :hasCost, true)

    # Set edge costs with node costs
    edge = Edge(v, cost_v)
    unpackStruct(mdg, edge, qnode.costs)

    # Set edge attributes for :src and :dst and specify edge is node cost
    set_prop!(mdg, edge, :src, inIdx)
    set_prop!(mdg, edge, :dst, -inIdx)
    set_prop!(mdg, edge, :isNodeCost, true)
    return
end


"""
Set the attributes of a directed edge corresponding to a qchannel
"""
function setEdgeAttrs(mdg, qchannel, src, dst)
    set_prop!(mdg, Edge(src, dst), :type, typeof(qchannel))
    for fieldType in fieldnames(typeof(qchannel))
        if fieldType == :costs
            unpackStruct(mdg, Edge(src, dst), halfCost(qchannel.costs))
        elseif fieldType == :src || fieldType == :dst
        # TODO: What is this code doing here?
        # if fieldType == :src
        #     # Set :src to :qid of node
        #     srcid = get_prop(mdg, src, :qid)
        #     set_prop!(mdg, Edge(src, dst), :src, srcid)
        # elseif fieldType == :dst
        #     # Set :dst to :qid of node
        #     dstid = get_prop(mdg, dst, :qid)
        #     set_prop!(mdg, Edge(src, dst), :dst, dstid)
        else
            propVal = getproperty(qchannel, fieldType)
            set_prop!(mdg, Edge(src, dst), fieldType, propVal)
        end
    end
    # Specify this edge corresponds to a channel, not node cost
    set_prop!(mdg, Edge(src, dst), :isNodeCost, false)
end


"""
Add a QChannel to the Network graph
"""
function c_addQChannel(mdg::MetaDiGraph, qchannel::QChannel)
    middle = g_addVertex!(mdg)
    set_prop!(mdg, middle, :isChannel, true)

    src = g_getVertex(mdg, qchannel.src)
    dst = g_getVertex(mdg, qchannel.dst)
    srcHasCost = get_prop(mdg, qchannel.src, :hasCost)
    dstHasCost = get_prop(mdg, qchannel.dst, :hasCost)

    if srcHasCost == true
        # Edge (-src, dst)
        minus_src = g_getVertex(mdg, -qchannel.src)
        add_edge!(mdg, minus_src, middle)
        add_edge(mdg, middle, dst)
        setEdgeAttrs(mdg, qchannel, minus_src, middle)
        setEdgeAttrs(mdg, qchannel, middle, dst)
    else
        # Edge(src, dst)
        add_edge!(mdg, src, middle)
        add_edge!(mdg, middle, dst)
        setEdgeAttrs(mdg, qchannel, src, middle)
        setEdgeAttrs(mdg, qchannel, middle, dst)
    end

    if qchannel.directed == false
        if dstHasCost == true
            # Edge(-dst, src)
            minus_dst = g_getVertex(mdg, -qchannel.dst)
            add_edge!(mdg, minus_dst, middle)
            add_edge!(mdg, middle, src)
            setEdgeAttrs(mdg, qchannel, minus_dst, middle)
            setEdgeAttrs(mdg, qchannel, middle, src)
        else
            # Edge(dst, src)
            add_edge!(mdg, dst, middle)
            add_edge!(mdg, middle, src)
            setEdgeAttrs(mdg, qchannel, dst, middle)
            setEdgeAttrs(mdg, qchannel, middle, src)
        end
    end
end


"""
Convert a QNetwork object to a directed MetaGraphs in Julia LightGraphs.
Directed MetaGraphs are used over weighted di-graphs is because they are more
performant at removing edges.
"""
function MetaDiGraph(net::BasicNetwork, nodeCosts::Bool = false)::AbstractGraph
    ## MAIN ##
    mdg = MetaDiGraph()

    # QNetwork properties
    set_prop!(mdg, :nodeToVert, Dict{Int, Int}())
    set_prop!(mdg, :numNodes, net.numNodes)
    set_prop!(mdg, :numChannels, net.numChannels)
    set_prop!(mdg, :nodeCosts, nodeCosts)

    # Add qnodes
    zeroCosts = Costs()
    for qnode in net.nodes
        c_addQNode!(mdg, qnode)
    end

    # Add channels
    for channel in net.channels
        c_addQChannel(mdg, channel)
    end
    return mdg
end
