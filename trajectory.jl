using Plots
gr()

include("env.jl")
using .Environment

s = []
for x in range(-0.5, stop=0.5, length=9)
    for y in range(-0.5, stop=0.5, length=9)
        push!(s, (x, y))
    end
end

designs = []
for s1 in s
    for s2 in s
        push!(designs, (s1, s2))
    end
end

xs = zeros(10001, 4); ys = zeros(10001, 4);
function positions(i, u)
    global xs, ys
    final_x = 10
    final_y = 10
    for (idx, (x, y, a)) in enumerate(u)
        dist = √(final_x^2 + final_y^2)
        if dist <= 0.075
            xs[idx, i] = final_x
            ys[idx, i] = final_y
        else
            xs[idx, i] = x
            ys[idx, i] = y
            final_x = x
            final_y = y
        end
    end
end

#cannon
l1, l2 = designs[6553]
model = Dense([0.0 1.0; 1.0 0.0], zeros(2))
p = (l1, l2, model)
for i in 1:4
    positions(i, evaluate(i, p))
end
plt = plot(xs, ys, lw=3, legend=false)
plot!(plt, [0], [0], markersize=8, seriestype=:scatter, lenged=false, color=:yellow)
savefig(plt, "figures/cannon_trace.png")

#ml
l1, l2 = designs[162]
model = Dense([0.0 1.0; -1.0 0.0], zeros(2))
p = (l1, l2, model)
for i in 1:4
    positions(i, evaluate(i, p))
end
plt = plot(xs, ys, lw=3, legend=false)
plot!(plt, [0], [0], markersize=8, seriestype=:scatter, lenged=false, color=:yellow)
savefig(plt, "figures/ml_trace.png")

#mcf
l1, l2 = designs[5922]
model = Dense([0.0 -1.0; 1.0 0.0], zeros(2))
p = (l1, l2, model)
for i in 1:4
    positions(i, evaluate(i, p))
end
plt = plot(xs, ys, lw=3, legend=false)
plot!(plt, [0], [0], markersize=8, seriestype=:scatter, lenged=false, color=:yellow)
savefig(plt, "figures/mcf_trace.png")

