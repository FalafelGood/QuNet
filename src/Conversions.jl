"""
Functions for converting QNetwork objects into more optimised graph types.
These functions integrate with the master function convertNet!() in Network.jl
"""

"""
Convert a QNetwork object to a directed MetaGraphs in Julia LightGraphs.
Directed MetaGraphs are used over weighted di-graphs is because they are more
performant at removing edges.
"""
function toLightGraph(net::BasicNetwork, nodeCosts = false)::AbstractGraph

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
    Add qnode attributes to MetaDiGraph if it has no costs
    """
    function NoCostNode(mdg, qnode)::Nothing
        setVertexAttrs(mdg, qnode, qnode.id)
        # Set node cost attribute to false
        set_prop!(mdg, qnode.id, :hasCost, false)
        return
    end

    """
    Add qnode to MetaDiGraph if it has costs

    If a node has costs, this function splits the node in two; A "sink" and
    "spout" with a directed edge between them. Undirected channels that
    connect the node will also be split outside this function -- An incoming
    edge to the sink, an outgoing edge from the spout -- both with the same
    costs.

    A node that passes through this method is given the attribute hasCost for node
    cost, which is true if it has a cost and false otherwise. A node is a sink
    (or has no cost) if its :id is positive. If the id is negative, then it's a
    spout that connects to the node with corresponding positive :id.
    """
    function CostNode(mdg, qnode)::Nothing
        # Add new node, connect directed edge
        add_vertex!(mdg)
        inIdx = qnode.id
        outIdx = nv(mdg)
        add_edge!(mdg, inIdx, outIdx)

        # Set properties for both nodes
        setVertexAttrs(mdg, qnode, inIdx)
        setVertexAttrs(mdg, qnode, outIdx)

        # Set attributes :id and :nc
        set_prop!(mdg, outIdx, :id, -inIdx)
        set_prop!(mdg, inIdx, :hasCost, true)
        set_prop!(mdg, outIdx, :hasCost, true)

        # Set edge costs with node costs
        edge = Edge(inIdx, outIdx)
        unpackStruct(mdg, edge, qnode.costs)

        # Set edge attributes for :src and :dst and specify edge is node cost
        set_prop!(mdg, edge, :src, inIdx)
        set_prop!(mdg, edge, :dst, -inIdx)
        set_prop!(mdg, edge, :isNodeCost, true)
        return
    end

    """
    Set the attributes of a directed edge given a qchannel, source, destination
    meta-source and meta-destanation (i.e. the :id attribute of the QNode)
    """
    function setEdgeAttrs(mdg, qchannel, src, dst)
        set_prop!(mdg, Edge(src, dst), :type, typeof(qchannel))
        for fieldType in fieldnames(typeof(qchannel))
            if fieldType == :costs
                unpackStruct(mdg, Edge(src, dst), qchannel.costs)
            elseif fieldType == :src
                # Set :src to :id of node
                srcid = get_prop(mdg, src, :id)
                set_prop!(mdg, Edge(src, dst), :src, srcid)
            elseif fieldType == :dst
                # Set :dst to :id of node
                dstid = get_prop(mdg, dst, :id)
                set_prop!(mdg, Edge(src, dst), :dst, dstid)
            else
                propVal = getproperty(qchannel, fieldType)
                set_prop!(mdg, Edge(src, dst), fieldType, propVal)
            end
        end
        # Specify this edge corresponds to a channel, not node cost
        set_prop!(mdg, Edge(src, dst), :isNodeCost, false)
    end

    """
    Add edges corresponding to a qchannel if one or both node have costs.
    """
    function addEdgeFromChannel(mdg, qchannel)
        srcHasCost = get_prop(mdg, qchannel.src, :hasCost)
        dstHasCost = get_prop(mdg, qchannel.dst, :hasCost)

        if srcHasCost == true
            # Edge (-src, dst)
            minus_src = mdg.metaindex[:id][-qchannel.src]
            dst = qchannel.dst
            add_edge!(mdg, minus_src, dst)
            setEdgeAttrs(mdg, qchannel, minus_src, dst)
        else
            # Edge(src, dst)
            add_edge!(mdg, qchannel.src, qchannel.dst)
            setEdgeAttrs(mdg, qchannel, qchannel.src, qchannel.dst)
        end

        if qchannel.directed == false
            if dstHasCost == true
                # Edge(-dst, src)
                minus_dst = mdg.metaindex[:id][-qchannel.dst]
                add_edge!(mdg, minus_dst, qchannel.src)
                setEdgeAttrs(mdg, qchannel, minus_dst, qchannel.src)
            else
                # Edge(dst, src)
                add_edge!(mdg, qchannel.dst, qchannel.src)
                setEdgeAttrs(mdg, qchannel, qchannel.dst, qchannel.src)
            end
        end
    end

    ## MAIN ##
    mdg = MetaDiGraph(net.numNodes)

    # Add QNetwork attributes
    set_prop!(mdg, :numNodes, net.numNodes)
    set_prop!(mdg, :numChannels, net.numChannels)
    set_prop!(mdg, :nodeCosts, nodeCosts)

    # Add qnodes
    zeroCosts = Costs()
    for qnode in net.nodes
        if nodeCosts == true && qnode.costs != zeroCosts
            # Add node with costs
            CostNode(mdg, qnode)
        else
            NoCostNode(mdg, qnode)
        end
    end
    # This will let us access literal node indices later with mdg.metaindex[:id]
    set_indexing_prop!(mdg, :id)

    # Add channels
    for channel in net.channels
        addEdgeFromChannel(mdg, channel)
    end
    return mdg
end

"""
Convert a vertex in MetaDiGraph back to a Qnode
"""
function vertexToQnode(mdg::MetaDiGraph, vertex::Int)
    vprops = props(mdg, vertex)
    type = get_prop(mdg, vertex, :type)
    fieldnames()
end

"""
Convert an edge in MetaDiGraph back to a QChannel
"""
function edgeToQchannel(mdg:: MetaDiGraph, e::Edge)
    #TODO
end

"""
Update a metaDiGraph by some time increment
"""
function updateGraph!(mdg::MetaDiGraph, dt)
    """
    Get all dynamic objects from MetaDiGraph (I.E. those that have a corresponding
    update! method)
    """
    function getDynamicObjs(g::AbstractMetaGraph, obj::Union{Integer, Edge})
        typeProp = get_prop(g, obj, :type)
        if typeProp <: DynamicNode
            return true
        elseif typeProp <: DynamicChannel
            return true
        end
        return false
    end
    dyVerts = filter_vertices(mdg, getDynamicObjs)
    dyEdges = filter_edges(mdg, getDynamicObjs)
    for vertex in dyVerts
        # TODO make QNode
        vertexToQnode(mdg, vertex)
        Base.@kwdef struct dummyNode
        newNode.update!(newNode, dt)
        # TODO update vertex properties
    end
    for edge in dyEdges
        # TODO make QChannel
        newChannel.update!(newChannel, dt)
        # Update channel properties
    end
end
