num_trials = 1000::Int64
max_pairs = 50::Int64
grid_size = 10::Int64
time_depth = 20::Int64
asynchronus_weight = 10*eps(Float64)

datafile = "data/bandwidth_userpairs"

d = Dict{Symbol, Any}()
@pack! d = num_trials, max_pairs, grid_size, time_depth, asynchronus_weight, max_depth_data,
max_depth_mem_data, max_depth_err, max_depth_mem_err, pathcount_data, pathcount_mem, pathcount_data_err, pathcount_mem_err
save("$datafile.jld", "data", d)
