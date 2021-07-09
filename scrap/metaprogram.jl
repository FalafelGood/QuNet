"""
Me noodling around with some metaprogramming tricks.
God help me, and you reading this pray for me

Most useful debugging tool:
ex = macroexpand(Main, :(@makesStruct Hello))
"""

macro makeStruct(name)
    return :(Base.@kwdef struct $name end)
end

macro makeP(name)
    quote
        Base.@kwdef struct $name end
    end
end

"""
Heh, make PP
"""
macro makePP(name, args)
    quote
        Base.@kwdef mutable struct $name
            for arg in args
            println(args)
            end
        end
    end
end

macro fill(args)
    for arg in args
        println(args)
    end
end
