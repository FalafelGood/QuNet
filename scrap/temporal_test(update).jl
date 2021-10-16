"""
TEST FILE FOR VARIOUS TEMPORAL META GRAPH THINGS
"""

using QuNet
using LightGraphs, SimpleWeightedGraphs, GraphPlot, MetaGraphs, Plots, Colors, Statistics
using LaTeXStrings
using JLD
using Parameters

datafile = "data/timedepth_test"

num_trials = 100::Int64
timedepth = 5
num_pairs = 8::Int64
grid_size = 4::Int64
async_cost = 0.001


G = GridNetwork(grid_size, grid_size)
# Create a Temporal Graph from G with timedepth i
T = QuNet.TemporalGraph(G, timedepth, memory_costs = zero_costvector())
# Get data
p, p_e, pat, pat_e = net_performance(T, num_trials, num_pairs, max_paths=4,
async_cost=async_cost, src_layer=-1, dst_layer=3)

println("p")
println("$p")
println("pat")
println("$pat")
