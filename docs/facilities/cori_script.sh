#!/bin/bash
#SBATCH -N 512
#SBATCH -C knl,quad,flat
#SBATCH -p debug
#SBATCH -J myapp_run1
#SBATCH --mail-user=johndoe@nersc.gov
#SBATCH --mail-type=ALL
#SBATCH -t 00:30:00

#OpenMP settings:
export OMP_NUM_THREADS=34
export OMP_PLACES=threads
export OMP_PROC_BIND=spread


#run the application:
srun -n 2048 -c 68 --cpu_bind=cores numactl -p 1 myapp.x
