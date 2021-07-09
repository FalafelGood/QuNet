using LightGraphs
using MetaGraphs
using JLD2

trysave = false

if trysave == true
    graph1 = MetaDiGraph(1)
    graph2 = MetaDiGraph(2)
    set_prop!(graph1, :color, "red")
    set_prop!(graph2, :color, "blue")
    @save "test.mg" graph1 graph2
else
    @load "test.mg" graph1
end
