using PyPlot
using CSV
using DataFrames

df = DataFrame(CSV.File("data/heat_2500pair.csv"))
println(df)
