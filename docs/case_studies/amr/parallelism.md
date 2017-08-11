# Parallelization

BoxLib implements parallelization through a hybrid MPI+OpenMP approach.

## MPI

At the coarsest level, BoxLib decomposes the problem domain into rectangular
boxes, and distributes these among MPI processes. Each process follows an
"owner computes" model, wherein it loops over its own boxes, executing Fortran
kernels on each box in series. An example is shown in the figure below, where
the red and green boxes are assigned to the same MPI process.

!["BoxLib box distribution"][boxlib_boxes]
[boxlib_boxes]: images/cc_validbox.png "BoxLib box distribution"

## OpenMP

BoxLib adds an additional layer of parallelism within each MPI process through
OpenMP threading, specifically by decomposing its set of boxes into a set of
smaller "tiles", which are then distributed among OpenMP threads. Although
these tiles can be arbitrarily shaped, by default they are pencil-shaped, being
long in the stride-1 memory access dimension (the x-dimension in Fortran
kernels), and short in the other two dimensions, in order to attain high cache
reuse and optimal hardware memory prefetching. As with the MPI parallelism, the
OpenMP tile box parallelism also follows an "owner computes" model, but at the
finer-grained thread level, rather than at the process level.

This OpenMP parallelism is illustrated in the figure below. The box
distribution is the same as in the figure above, except in this case each box
is further decomposed into smaller tiles. BoxLib then builds a list of all
tiles comprising all boxes owned by a given MPI process, and distributes the
list among the OpenMP threads in the process. The figure below illustrates this
process by color-coding each tile, with unique threads assigned to each color,
such that the same thread may operate on tiles spanning different boxes. This
approach avoids unnecessary thread synchronization which would occur if threads
were distributed among tiles within each box.

!["BoxLib OpenMP tiling"][boxlib_tiling]
[boxlib_tiling]: images/cc_tilebox.png "BoxLib OpenMP tiling"

The figures on this page are taken from the AMReX User's Guide.
