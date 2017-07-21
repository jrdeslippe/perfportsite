## Parallelization

In BoxLib, parallelization is realized through a hybrid MPI+OpenMP approach. It
decomposes the problem domain into rectangular boxes, and distributes these
among MPI processes. Each process follows an "owner computes" model, wherein it
loops over its own boxes, executing Fortran kernels on each box in series.
BoxLib adds an additional layer of parallelism within each MPI process through
OpenMP threading, specifically by decomposing its set of boxes into a set of
smaller "tiles", which are then distributed among OpenMP threads. Although
these tiles can be arbitrarily shaped, by default they are pencil-shaped, being
long in the stride-1 memory access dimension (the x-dimension in Fortran
kernels), and short in the other two dimensions, in order to attain high cache
reuse and optimal hardware memory prefetching. As with the MPI parallelism, the
OpenMP tile box parallelism also follows an "owner computes" model, but at the
finer-grained thread level, rather than at the process level.
