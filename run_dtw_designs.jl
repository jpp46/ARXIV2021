using DelimitedFiles, Statistics, Combinatorics
using Distances: SqEuclidean
using BSON: @load

include("dtw.jl")
using .DTW

include("env.jl")
using .Environment

seed = parse(Int, ARGS[1])

function compute_sensors(u, l1, l2)
    s1 = Vector{Float64}(undef, 10001)
    s2 = Vector{Float64}(undef, 10001)
    for (idx, (x, y, a)) in enumerate(u)
        s1[idx] = sensor_value([x, y, a], l1...)
        s2[idx] = sensor_value([x, y, a], l2...)
    end
    return s1, s2
end


function run_design(genome, eval_num)
    println("running $seed, $eval_num")
    global model
    l1 = (genome[1], genome[2])
    l2 = (genome[3], genome[4])
    model = Dense([0.0 genome[5]; genome[6] 0.0], zeros(2))
    p = (l1, l2, model)

    results = []
    for i in 1:4
        u = evaluate(i, p)
        s1, s2 = compute_sensors(u, l1, l2)
        push!(results, (s1, s2))
    end

    dtw_s1 = []; dtw_s2 = [];
    for (a, b) in combinations(results, 2)
        push!(dtw_s1, dtw(a[1], b[1]));
        push!(dtw_s2, dtw(a[2], b[2]));
    end
    dtw_score = mean([mean(dtw_s1), mean(dtw_s2)])
    println("done")
    return dtw_score
end

file_names = readdir("borg_moea/designs_$seed"); progress = []
for file_name in file_names
    global progress
    if split(file_name, ".")[2] == "genome"
        @load "borg_moea/designs_$seed/$file_name" genome
        eval_num = parse(Int, split(file_name, ".")[1])
        dtw_score = run_design(genome, eval_num)
        push!(progress, (eval_num, dtw_score))
    end
end


open("borg_moea/designs_$seed/dtw_progress.csv", "w") do io
    write(io, "evals, dtw\n")
    for (eval_num, dtw_score) in sort(progress)
        write(io, "$eval_num, $dtw_score\n")
    end
end


