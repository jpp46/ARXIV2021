using Plots, CSV, DelimitedFiles, Statistics, HypothesisTests, LaTeXStrings
gr()

can_idx = 6553
### HEATM MAP ###
all_ml = []; all_mcf = [];
for idx in 1:6561
    global best_ml, best_mcf
    res = Nothing
    open("metrics/$idx.csv", "r") do io
        res = readdlm(io)
    end
    l1 = res[1, :]; l2 = res[2, :];
    ml = res[3, 1]; mcf = res[3, 2];
    push!(all_ml, (ml, mcf, idx, l1, l2))
    push!(all_mcf, (mcf, ml, idx, l1, l2))
end
to_plot = []
for (b_ml, b_mcf) in zip(sort(all_ml)[end-1:end], sort(all_mcf)[end-1:end])
    push!(to_plot, b_ml)
    push!(to_plot, (b_mcf[2], b_mcf[1], b_mcf[3], b_mcf[4], b_mcf[5]))
end
for b_mcf in sort(all_mcf)[1:2]
    push!(to_plot, (b_mcf[2], b_mcf[1], b_mcf[3], b_mcf[4], b_mcf[5]))
end
push!(to_plot, all_ml[can_idx])

w = range(-1.0, stop=1.0, length=121)
for (i, design) in enumerate(to_plot)
    ml, mcf, idx, l1, l2 = design
    mat = Nothing
    open("metrics/$(idx)_mat.csv", "r") do io
        mat = readdlm(io)
    end
    lab = L"M_{L}=%$(round(ml, digits=4)), M_{CI}=%$(round(mcf, digits=4)), L_{1}=%$l1, L_{2}=%$l2"
    plt = heatmap(w, w, mat, title=lab, c=:roma, clim=(0.0, 4.0))
    savefig(plt, "figures/heatmap_$idx.png")
end


### CORR OF ML & MCF ###
mls = []
mcfs = []
for idx in 1:6561
    global mls, mcfs
    res = Nothing
    open("metrics/$idx.csv", "r") do io
        res = readdlm(io)
    end
    l1 = res[1, :]; l2 = res[2, :];
    ml = res[3, 1]; mcf = res[3, 2];
    (ml <= 0 || mcf <= 0 || isnan(ml) || isnan(mcf)) && continue
    push!(mls, ml)
    push!(mcfs, mcf)
end
r = isnan(cor(mls, mcfs)) ? 0 : cor(mls, mcfs)
p = pvalue(OneSampleZTest(atanh(r), 1, 6561-3))
p = p == 0 ? "p < 0.001" : "p=$p"
plt = scatter(mls, mcfs, xlabel=L"M_{L}", ylabel=L"M_{CI}", title="r=$(round(r, digits=4))\n$p",
    markercolor=:blue, markersize=3, legend=false)
savefig(plt, "figures/ml_mcf_corr.png")


### CORR OF ML & EVALS ###
for method in [:random_search, :generating_set_search, :separable_nes, :de_rand_2_bin]
    global r, p, plt, mls
    mls = []
    means = []; stds = [];
    for idx in 1:6561
        res = Nothing
        open("metrics/$idx.csv", "r") do io
            res = readdlm(io)
        end
        l1 = res[1, :]; l2 = res[2, :];
        ml = res[3, 1]; mcf = res[3, 2];
        (ml <= 0 || mcf <= 0 || isnan(ml) || isnan(mcf)) && continue
        push!(mls, ml)
        
        evals = []
        for seed in 1:10
            csv = CSV.File("$method/design-$(idx)_seed-$(seed).csv")
            jdx = findfirst(row -> row[5] == 4, csv)
            if jdx == nothing
                push!(evals, 500)
            else
                push!(evals, csv[jdx][1])
            end
        end
        push!(means, mean(evals)); push!(stds, std(evals))
    end
    r = isnan(cor(mls, means)) ? 0 : cor(mls, means)
    p = pvalue(OneSampleZTest(atanh(r), 1, 6561-3))
    p = p == 0 ? "p < 0.001" : "p=$p"
    plt = scatter(mls, means, xlabel=L"M_{L}", ylabel="EVALS", title="r=$(round(r, digits=4))\n$p",
        markercolor=:blue, markersize=3, legend=false)
    savefig(plt, "figures/$(method)_ml_evals_corr.png")
end


### CORR OF MCF & EVALS
for method in [:random_search, :generating_set_search, :separable_nes, :de_rand_2_bin]
    global r, p, plt, mcfs
    mcfs = []
    means = []; stds = [];
    for idx in 1:6561
        res = Nothing
        open("metrics/$idx.csv", "r") do io
            res = readdlm(io)
        end
        l1 = res[1, :]; l2 = res[2, :];
        ml = res[3, 1]; mcf = res[3, 2];
        (ml <= 0 || mcf <= 0 || isnan(ml) || isnan(mcf)) && continue
        push!(mcfs, mcf)
        
        evals = []
        for seed in 1:10
            csv = CSV.File("$method/design-$(idx)_seed-$(seed).csv")
            jdx = findfirst(row -> row[5] == 4, csv)
            if jdx == nothing
                push!(evals, 500)
            else
                push!(evals, csv[jdx][1])
            end
        end
        push!(means, mean(evals)); push!(stds, std(evals))
    end
    r = isnan(cor(mcfs, means)) ? 0 : cor(mcfs, means)
    p = pvalue(OneSampleZTest(atanh(r), 1, 6561-3))
    p = p == 0 ? "p < 0.001" : "p=$p"
    plt = scatter(mcfs, means, xlabel=L"M_{CI}", ylabel="EVALS", title="r=$(round(r, digits=4))\n$p",
        markercolor=:blue, markersize=3, legend=false)
    savefig(plt, "figures/$(method)_mcf_evals_corr.png")
end

### EVO VS EVO w/Design ###
results = []
min_evals = 1000
max_evals = 0
for method in [:borg_moea, :borg_moea_fixed]
    global results, min_evals, max_evals
    evals = Vector{Float64}()
    for seed in 1:30
        csv = CSV.File("$method/seed-$(seed).csv")
        jdx = findfirst(row -> row[5] == 4, csv)
        if jdx == nothing
            push!(evals, 500)
        else
            push!(evals, csv[jdx][1])
        end
        min_evals = csv[1][1] < min_evals ? csv[1][1] : min_evals
        max_evals = csv[end][1] > max_evals ? csv[end][1] : max_evals
    end
    push!(results, evals)
end
p = pvalue(MannWhitneyUTest(results[1], results[2]))
println("Evolution +Morpho -- mean: ", mean(results[1]), " std: ", std(results[1]))
println("Evolution Fixed Morpho -- mean: ", mean(results[2]), " std: ", std(results[2]))
println(p)

### Borg Evo Progress ###
all_ys = []
for method in [:borg_moea, :borg_moea_fixed]
    ys = zeros(30, max_evals)
    for seed in 1:30
        csv = CSV.File("$method/seed-$(seed).csv")
        y = zeros(max_evals)
        for row in csv
            evaln = row[1]
            sucsn = row[5]
            y[evaln] = sucsn
        end
        idx = findfirst(n -> n > 0, y)
        for i in min_evals:max_evals
            if y[i] <= 0
                y[i] = y[idx]
            else
                idx = i
            end
        end
        ys[seed, :] .= y 
    end
    push!(all_ys, ys)
end
xs = collect(min_evals:max_evals)

function confint(stddev, n)
    Z = 1.960
    Z*(stddev/√n)
end

borg_moea_y = mean(all_ys[1], dims=1)[:]
borg_moea_std = std(all_ys[1], dims=1)[:]
borg_moea_confint = confint.(borg_moea_std, length(xs))
y = borg_moea_y[min_evals:max_evals]; σ = borg_moea_confint[min_evals:max_evals]
plt = plot(xs, y, ribbon=σ, legend=:bottomright,
    c=:blue, fc=:blue, fa=0.3, label="Optimizing Design and Control", xlabel="Evals", ylabel="Avg Success")

borg_moea_fixed_y = mean(all_ys[2], dims=1)[:]
borg_moea_fixed_std = std(all_ys[2], dims=1)[:]
borg_moea_fixed_confint = confint.(borg_moea_fixed_std, length(xs))
y = borg_moea_fixed_y[min_evals:max_evals]; σ = borg_moea_fixed_confint[min_evals:max_evals]
plot!(plt, xs, y, ribbon=σ, fillalpha=0.3, legend=:bottomright,
    c=:red, fc=:red, fa=0.3, label="Optimizing Control", xlabel="Evals", ylabel="Avg Success")
savefig(plt, "figures/borg_comparison.png")

ys = zeros(30, max_evals)
for seed in 1:30
    global ys
    csv = CSV.File("borg_moea/designs_$(seed)/dtw_progress.csv")
    local y = zeros(max_evals)
    for row in csv
        evaln = row[1]
        dtw = row[2]
        y[evaln] = dtw
    end
    idx = findfirst(n -> n > 0, y)
    for i in min_evals:max_evals
        if y[i] <= 0
            y[i] = y[idx]
        else
            idx = i
        end
    end
    ys[seed, :] .= y 
end
dtw_y = mean(ys, dims=1)[:]
dtw_std = std(ys, dims=1)[:]
dtw_confint = confint.(dtw_std, length(xs))
y = dtw_y[min_evals:max_evals]; σ = dtw_confint[min_evals:max_evals]
plt = plot(xs, y, ribbon=σ, legend=false,
    c=:blue, fc=:blue, fa=0.3, xlabel="Evals", ylabel="Avg DTW Distance")
savefig(plt, "figures/dtw.png")


