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
#SBATCH --ntasks=4
#SBATCH --mem=8G

#SBATCH --time=14:00:00
#SBATCH --partition=bluemoon

#SBATCH --job-name=EDL_evo_$(idx)

#SBATCH --mail-user=jpowers4@uvm.edu
#SBATCH --mail-type=FAIL

cd \${SLURM_SUBMIT_DIR}

julia run_dtw_designs.jl $idx
"
    open("job_$(idx).sh", "w") do f
        write(f, script)
    end
    run(`sbatch job_$(idx).sh`)
    sleep(2)
    run(`rm job_$(idx).sh`)
end

for seed in 1:30
    run_job(seed)
end