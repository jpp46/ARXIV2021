using BlackBoxOptim, DelimitedFiles, Random
using BlackBoxOptim: num_func_evals
using BSON: @save

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

model = Dense([0.0 1.0; 1.0 0.0], zeros(2))
l1, l2 = designs[6553]
seed = 0



function value(u)
    smallest_dist = typemax(Float64)
    for (x, y, a) in u
        dist = √(x^2 + y^2)
        if dist < smallest_dist
            smallest_dist = dist
        end
    end
    return Float64(smallest_dist)
end

function callback(oc)
    global model
    evals = num_func_evals(oc)
    agg_fitness = best_fitness(oc).orig

    v1 = agg_fitness[1]
    v2 = agg_fitness[2]
    v3 = agg_fitness[3]
    v4 = agg_fitness[4]
    mean = sum([v1, v2, v3, v4])/4
    best = minimum([v1, v2, v3, v4])
    worst = maximum([v1, v2, v3, v4])
    s_num = count(v -> v < 0.075, [v1, v2, v3, v4])
    open("borg_moea_fixed/seed-$seed.csv", "a") do io
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
    return (v1, v2, v3, v4)
end

for iter in 1:30
    global seed = iter
    println(iter)
    Random.seed!(iter)
    open("borg_moea_fixed/seed-$seed.csv", "w") do io
        write(io, "evals, mean, best, worst, success num\n")
    end

    res = bboptimize(fitness;
        SearchRange=[(-1.0, 1.0), (-1.0, 1.0)], NumDimensions=6,
        Method=:borg_moea, MaxFuncEvals=500,
        FitnessScheme=ParetoFitnessScheme{4}(is_minimizing=true),
        CallbackFunction=callback, CallbackInterval=0.0, TraceMode=:silent)
    genome = best_candidate(res)
    @save "borg_moea_fixed/seed-$seed.genome" genome
end




