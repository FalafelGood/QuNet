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
"""
function c_addQNode!(mdg::MetaDiGraph, qnode::QNode, nodeCosts::Bool=false)
    # Add vertex to graph with default metaproperties
    v = g_addVertex!(mdg)
    # set vertex props to be qnode fields
    setVertexAttrs(mdg, qnode, v)
    mapNodeToVert!(mdg, qnode.qid, v)
end


"""
Set the costs of a directed edge corresponding to a qchannel.
(Because there are two of these in every channel, the costs are set to half
their usual value)
"""
function setEdgeCosts(mdg, qchannel, src, dst)
    unpackStruct(mdg, Edge(src, dst), halfCost(qchannel.costs))
end

"""
Set the attributes of a vertex corresponding to a qchannel.
(Essentially all of the attributes of the qchannel except for the costs which
go to the edges)
"""
function setChanAttrs(mdg, v, qchannel)
    set_prop!(mdg, v, :isChannel, true)
    set_prop!(mdg, v, :type, typeof(qchannel))
    if qchannel.directed == false
        set_prop!(mdg, v, :reverseCapacity, qchannel.capacity)
    end
    for fieldType in fieldnames(typeof(qchannel))
        if fieldType != :costs
            propVal = getproperty(qchannel, fieldType)
            set_prop!(mdg, v, fieldType, propVal)
        end
    end
end

"""
Add a QChannel to the Network graph and return the vertex corresponding
to the channel
"""
function c_addQChannel(mdg::MetaDiGraph, qchannel::QChannel)
    middle = g_addVertex!(mdg)
    setChanAttrs(mdg, middle, qchannel)

    srcVert = g_getVertex(mdg, qchannel.src)
    dstVert = g_getVertex(mdg, qchannel.dst)

    # Edge(src, dst)
    add_edge!(mdg, srcVert, middle)
    add_edge!(mdg, middle, dstVert)
    setEdgeCosts(mdg, qchannel, srcVert, middle)
    setEdgeCosts(mdg, qchannel, middle, dstVert)

    if qchannel.directed == false
        # Edge(dst, src)
        add_edge!(mdg, dstVert, middle)
        add_edge!(mdg, middle, srcVert)
        setEdgeCosts(mdg, qchannel, dstVert, middle)
        setEdgeCosts(mdg, qchannel, middle, srcVert)
    end
    return middle
end


"""
Convert a QNetwork object to a directed MetaGraphs in Julia LightGraphs.
Directed MetaGraphs are used over weighted di-graphs is because they are more
performant at removing edges.
"""
function MetaDiGraph(net::BasicNetwork)::AbstractGraph
    ## MAIN ##
    mdg = MetaDiGraph()

    # QNetwork properties
    set_prop!(mdg, :nodeToVert, Dict{Int, Int}())
    set_prop!(mdg, :numNodes, net.numNodes)
    set_prop!(mdg, :numChannels, net.numChannels)

    # Add qnodes
    for qnode in net.nodes
        c_addQNode!(mdg, qnode)
    end

    # Add channels
    for channel in net.channels
        c_addQChannel(mdg, channel)
    end
    return mdg
end
