#!/bin/bash
#COBALT -t 30
#COBALT --attrs mcdram=cache:numa=quad
#COBALT -A <yourALCFProjectName>
echo "Starting Cobalt job script"
export n_nodes=$COBALT_JOBSIZE
export n_mpi_ranks_per_node=32
export n_mpi_ranks=$(($n_nodes * $n_mpi_ranks_per_node))
export n_openmp_threads_per_rank=4
export n_hyperthreads_per_core=2
export n_hyperthreads_skipped_between_ranks=4
aprun -n $n_mpi_ranks -N $n_mpi_ranks_per_node \
  --env OMP_NUM_THREADS=$n_openmp_threads_per_rank -cc depth \
  -d $n_hyperthreads_skipped_between_ranks \
  -j $n_hyperthreads_per_core \
  <executable> <executable args>
