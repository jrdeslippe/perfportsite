#!/bin/bash
#PBS -A <yourOLCFProjectName>
#PBS -N test
#PBS -j oe
export n_nodes=$JOBSIZE
export n_mpi_ranks_per_node=8
export n_mpi_ranks=$(($n_nodes * $n_mpi_ranks_per_node))

cd $MEMBERWORK/<yourOLCFProjectName>
date

export OMP_NUM_THREADS=2

aprun -n $n_mpi_ranks -N $n_mpi_ranks_per_node \
  -d 2  <executable> <executable args>
