__precompile__(true)

module QuNet

# TODO: Update what we should be using vs importing. Be discriminating!
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs
using LinearAlgebra, StatsBase, Statistics
using Documenter, Colors, Plots, LaTeXStrings

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
abstract type QNetwork <: QObject end

TIME_STEP = 0.01

# WARNING The order of these is important.
# Don't change them willy-nilly unless you like screaming
include("Costs.jl")
include("Network.jl")
include("TemporalGraphs.jl")
include("CostVector.jl")
include("Node.jl")
include("Channel.jl")
include("Percolation.jl")
include("Routing.jl")
include("Plot.jl")
include("Utilities.jl")
include("Benchmarking.jl")
include("GraphInterface.jl")
include("Generators.jl")
include("Conversions.jl")

export
# Abstract Classes
QObject, QNode, QChannel, QNetwork,

# # Benchmarking.jl
# percolation_bench, dict_average, dict_err, make_user_pairs, net_performance,

# Channel.jl
BasicChannel, FibreChannel, AirChannel,

# Costs.jl
Costs, dE_to_E, E_to_dE, dF_to_F, F_to_dF,

# # CostVector.jl
# zero_costvector, unit_costvector, convert_costs, get_pathcv,

# Network.jl
BasicNetwork, addNode!, hasChannel, getChannelIdx, addChannel!, convertNet!,
#update, #refresh_graph!,

# Node.jl
BasicNode, CartCoords, CartNode, CartVelocity, CartSatNode,

# Percolation.jl

# # Plot.jl
# gplot,

# # GraphInterface.jl
# hard_rem_edge!,

# Generators
GridNetwork

# # Routing.jl
# shortest_path,

# TemporalGraphs.jl

# # Utilities.jl
# purify
end
