using Plots

x = collect(1:100)
y1 = rand(100)
y1p = rand(100)
y1pp = rand(100)
y2 = rand(100)
y3 = rand(100)
y4 = rand(100)

p1 = plot(x, y1)
plot!(x, y1p)
plot!(x, y1pp)
p2 = plot(x, y2)
p3 = plot(x, y3)
p4 = plot(x, y4)

plot(p1, p2, p3, p4, layout=4)
