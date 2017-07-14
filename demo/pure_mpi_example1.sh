#!/bin/bash -l
#SBATCH -p debug
#SBATCH -N 64
#SBATCH -t 00:20:00
#SBATCH -J my_job
#SBATCH -L SCRATCH
#SBATCH -C haswell

# an extra -c 2 flag is optional for fully packed pure MPI
srun -n 2048 ./mycode.exe
