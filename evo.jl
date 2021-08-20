using BlackBoxOptim, DelimitedFiles, Random
using BlackBoxOptim: num_func_evals
using BSON: @save

include("env.jl")
using .Environment

idx = parse(Int, ARGS[1])
seed = 1
search_methods = [:random_search, :generating_set_search, :separable_nes, :de_rand_2_bin]
method = Nothing

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

l1, l2 = designs[idx]
model = Dense([0.0 1.0; 1.0 0.0], zeros(2))

function value(u)
    smallest_dist = typemax(Float64)
    for (x, y, a) in u
        dist = √(x^2 + y^2)
        if dist < smallest_dist
            smallest_dist = dist
        end
    end
    return smallest_dist
end

function callback(oc)
    global model
    evals = num_func_evals(oc)
    genome = best_candidate(oc)
    model.W .= [0.0 genome[1]; genome[2] 0.0]
    p = (l1, l2, model)

    v1 = value(evaluate(1, p))
    v2 = value(evaluate(2, p))
    v3 = value(evaluate(3, p))
    v4 = value(evaluate(4, p))
    mean = sum([v1, v2, v3, v4])/4
    best = minimum([v1, v2, v3, v4])
    worst = maximum([v1, v2, v3, v4])
    s_num = count(v -> v < 0.075, [v1, v2, v3, v4])
    open("$method/design-$(idx)_seed-$seed.csv", "a") do io
        write(io, "$evals, $mean, $best, $worst, $s_num\n")
    end
end

function fitness(genome)
    global model
    model.W .= [0.0 genome[1]; genome[2] 0.0]
    p = (l1, l2, model)

    v1 = value(evaluate(1, p))
    v2 = value(evaluate(2, p))
    v3 = value(evaluate(3, p))
    v4 = value(evaluate(4, p))
    return sum([v1, v2, v3, v4])
end

for midx in 1:length(search_methods)
    println("running $(search_methods[midx]) on design $idx")
    for iter in 1:10
        println(iter)
        global seed = iter
        global method = search_methods[midx]
        Random.seed!(seed+midx+iter+idx)
        open("$method/design-$(idx)_seed-$seed.csv", "w") do io
            write(io, "evals, mean, best, worst, success num\n")
        end

        res = bboptimize(fitness; SearchRange=(-1.0, 1.0), NumDimensions=2,
            Method=method, PopSize=10, MaxFuncEvals=500,
            CallbackFunction=callback, CallbackInterval=0.0, TraceMode=:silent)
    end
    println()
end
