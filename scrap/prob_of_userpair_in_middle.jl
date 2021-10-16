using Plots



max_n = 30
n_arr = collect(5:max_n)
probs = []
probs_corner = []
probs_line = []

for n in n_arr
    N_m = n^2 - 4*(n-1)
    prob = N_m / n^2 * (N_m-1) / (n^2 - 1)
    push!(probs, prob)

    # Prob at least one node is a corner node
    prob_corner = 4/n^2 + (n^2 - 4)/(n^2) * (4/(n^2-1))
    push!(probs_corner, prob_corner)

    # Prob that users end on same row or column
    prob_line = 2*(n-1)/(n^2 - 1)
    push!(probs_line, prob_line)
end

plot(n_arr, 1 .- probs, label="probs not middle")
plot!(n_arr, probs_corner, label="probs corner")
plot!(n_arr, probs_line, label="probs line")
