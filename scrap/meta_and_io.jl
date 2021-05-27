"""
Use jld save to a dictionary of variables, then unpack the dictionary after
load

NOT YET WORKING
"""

# using JSON
using JLD
using Parameters

"""
Plot the performance statistics of greedy_multi_path for 1 random end-user pair
over a range of graph sizes and for different numbers of max_path (1,2,3) (ie. the
maximum number of paths that can be purified by a given end-user pair.)
"""

# COOL BLACK MAGIC CODE
# Get the string of a variable identifier
# macro Name(arg)
#     string(arg)
# end

# function string_as_varname(s::AbstractString,v::Any)
#          s=Symbol(s)
#          @eval (($s) = ($v))
# end

# """
# Get a list of the symbolic variable names within scope.
# """
# function varnames()::Array{Symbol, 1}
#     # First 4 variables are modules, don't want to include them
#     vars = names(Main)[5:end]::Array{Symbol, 1}
#     # Filter ans
#     filter!(e->e!=:ans, vars)
#     return vars
# end

make_data = false
if make_data == true

    # Some example data
    a = 1
    b = 2.2
    c = [3 3; 3 3]

    # Pack dictionary with data using Parameters macro
    d = Dict{Symbol, Any}()
    @pack! d = a, b, c
    # Save data
    save("foo.jld", "data", d)
else
    # TODO Load data
    d = load("foo.jld")["data"]
    @unpack a, b, c = d
end

# function magic_save(filename::String, data...)
#     d = Dict{Symbol, Any}()
#     # @pack! d = data
#     # save("$filename.jld", "$filename", d)
# end

macro Magic_save(filename::String, data...)
    d = Dict{Symbol, Any}()
    @pack! d = data
    save("$filename.jld", "$filename", d)
end

macro Magic_load(filename::String, names...)
    d = load("$filename.jld")["$filename"]
    @unpack names = d
end

# function magic_load(filename::String, varnames...)
#     d = load("$filename.jld")["$filename"]
#     @unpack varnames = d
# end

e = 1
f = 2
g = 3
