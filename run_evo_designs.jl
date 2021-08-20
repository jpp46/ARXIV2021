using DelimitedFiles
using BSON: @load

include("env.jl")
using .Environment

seed = parse(Int, ARGS[1])

function success(u)
    smallest_dist = typemax(Float64)
    for (x, y, α) in u
        dist = √(x^2 + y^2)
        if dist < smallest_dist
            smallest_dist = dist
        end
    end
    if smallest_dist <= 0.075
        return 1
    else
        return 0
    end
end

function learning_metric(matrix)
    return count(v -> v==4, matrix)/length(matrix)
end

function resistance_metric(matrix)
    return count(v -> v==4, matrix)/count(v -> v > 0, matrix)
end

function run_design(genome, eval_num)
    l1 = (genome[1], genome[2])
    l2 = (genome[3], genome[4])
    println("running $seed, $eval_num")
    if !isfile("borg_moea/designs_$seed/$(eval_num).csv") && !isfile("borg_moea/designs_$seed/$(eval_num)_mat.csv")
        matrix = zeros(Int, 121, 121)
        for (i, w1) in enumerate(range(-1.0, stop=1.0, length=121))
            for (j, w2) in enumerate(range(-1.0, stop=1.0, length=121))
                model = Dense([0.0 w1; w2 0.0], zeros(2))
                p = (l1, l2, model)
                for k in 1:4
                    u = try
                        evaluate(k, p)
                    catch err
                        println("error on: ", w1, " ", w2)
                        [ones(3), ones(3), ones(3), ones(3)]
                    end
                    matrix[i, j] += success(u)
                end
            end
        end
        ml = learning_metric(matrix)
        mcf = resistance_metric(matrix)
        open("borg_moea/designs_$seed/$(eval_num).csv", "w") do io
            writedlm(io, [l1, l2, (ml, mcf)])
        end
        open("borg_moea/designs_$seed/$(eval_num)_mat.csv", "w") do io
            writedlm(io, matrix)
        end
    end
    println("done\n")
end

file_names = readdir("borg_moea/designs_$seed")
for file_name in file_names
    if split(file_name, ".")[2] == "genome"
        @load "borg_moea/designs_$seed/$file_name" genome
        run_design(genome, split(file_name, ".")[1])
    end
end


