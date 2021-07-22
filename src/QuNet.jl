__precompile__(true)

module QuNet

# TODO: Update what we should be using vs importing. Be discriminating!
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs
using LinearAlgebra, StatsBase, Statistics
using Documenter, Colors, Plots, LaTeXStrings
using StructEquality

# Satellite stuff
# using SatelliteToolbox
# using QuadGK

import SparseArrays:dropzeros!
import Base: *, print, string
import GraphPlot: gplot
import QuadGK: quadgk
import SatelliteToolbox: expatmosphere

abstract type QObject end
abstract type QNode <: QObject end
abstract type QChannel <: QObject end
abstract type StaticNode <: QNode end
abstract type DynamicNode <: QNode end
abstract type StaticChannel <: QChannel end
abstract type DynamicChannel <: QChannel end
abstract type QNetwork <: QObject end

# WARNING The order of these is important.
# Don't change them willy-nilly unless you like screaming
include("Costs.jl")
include("BasicNetwork.jl")
include("TemporalGraphs.jl")
include("Node.jl")
include("Channel.jl")
include("Percolation.jl")
include("Plot.jl")
include("Utilities.jl")
include("Benchmarking.jl")
include("MetaGraphs/NetInterface.jl")
include("MetaGraphs/NetConversion.jl")
include("Generators.jl")
include("Pathset.jl")
# include("MultiPath.jl")

export
# Abstract Classes
QObject, QNode, QChannel, QNetwork

# Channel.jl
BasicChannel, FibreChannel, AirChannel,

# Costs.jl
Costs, dE_to_E, E_to_dE, dF_to_F, F_to_dF,

# BasicNetwork.jl
BasicNetwork, addNode!, hasChannel, getChannelIdx, getChannel, addChannel!,
convertNet!,

# DynamicNetwork.jl

# Node.jl
BasicNode, CartCoords, CartNode, CartVelocity, CartSatNode,

# MetaGraphs

# NetConversion
# MetaDiGraph,

# NetInterface.jl
# g_remChannel!, g_getProp, g_edgeCosts, g_pathCosts, g_networkPath, g_removePath!,
# g_shortestPath, g_remShortestPath!, g_filterInactiveEdges, g_filterInactiveVertices,

# Percolation.jl

# # Plot.jl
# gplot,

# Generators
GridNetwork

# # Routing.jl
# shortest_path,

# TemporalGraphs.jl

# # Utilities.jl
# purify
end
