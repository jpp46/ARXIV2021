using DelimitedFiles

include("env.jl")
using .Environment

idx = parse(Int, ARGS[1])

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

function run_design()
    l1, l2 = designs[idx]
    println("running $idx")
    if !isfile("metrics/$idx.csv") && !isfile("metrics/$(idx)_mat.csv")
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
        open("metrics/$idx.csv", "w") do io
            writedlm(io, [l1, l2, (ml, mcf)])
        end
        open("metrics/$(idx)_mat.csv", "w") do io
            writedlm(io, matrix)
        end
    end
    println("done\n")
end

run_design()

