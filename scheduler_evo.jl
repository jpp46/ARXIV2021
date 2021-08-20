using Base

function num_jobs()
    original_stdout = stdout;
    (rd, wr) = redirect_stdout();
    run(`squeue -u jpowers4`);
    redirect_stdout(original_stdout);
    close(wr);
    lines = readlines(rd);
    if length(lines) == 0
        return 0
    end
    return (length(lines)-1)
end

function run_job(idx)
    script = 
"#!/bin/sh
#SBATCH --nodes=1
#SBATCH --ntasks=2
#SBATCH --mem=4G

#SBATCH --time=10:00:00
#SBATCH --partition=bluemoon

#SBATCH --job-name=EDL_$(idx)

#SBATCH --mail-user=jpowers4@uvm.edu
#SBATCH --mail-type=FAIL

cd \${SLURM_SUBMIT_DIR}

julia evo.jl $idx
"
    open("job_$(idx).sh", "w") do f
        write(f, script)
    end
    run(`sbatch job_$(idx).sh`)
    sleep(1)
    run(`rm job_$(idx).sh`)
end

s = []
for x in range(-0.5, stop=0.5, length=9)
    for y in range(-0.5, stop=0.5, length=9)
        push!(s, (x, y))
    end
end

designs = []
for s1 in s
    for s2 in s
        push!(designs, [s1, s2])
    end
end

search_methods = [:random_search, :generating_set_search, :separable_nes, :de_rand_2_bin]
for method in search_methods
    if !ispath("$method")
        mkdir("$method")
    end
end

idx = 1
while idx <= length(designs)
    global idx
    n = num_jobs()
    for _ in 1:(100-n)
        run_job(idx)
        idx += 1
    end
    sleep(120)
end