# Geometric Multigrid

Many problems encountered in BoxLib applications require solutions to linear
system, e.g., elliptic PDEs such as the Poisson equation for self-gravity, and
the diffusion equation. BoxLib therefore includes geometric multigrid solvers
for solving problems which use both cell-centered and nodal data. For this
project, we have focused on the cell-centered solver due to its relative
simplicity compared to the nodal solver.

Geometric multigrid is an iterative method for solving linear problems which
contains roughly 4 steps:

  * relaxation
  * restriction
  * prolongation
  * coarse-grid linear solve (either approximate or exact)

Although here we will not discuss the details of the geometric multigrid method
(an entire literature exists on the topic), we summarize each of these steps
below as they pertain to computational algorithms.

## Relaxation

(WIP)

## Restriction

During a restriction, the value of a field on a fine grid is approximated on a
coarser grid. This is typically done by averaging values of the field on fine
grid points onto the corresponding grid points on the coarse grid. In BoxLib,
the algorithm is the following:

```fortran
do k = lo(3), hi(3)
  k2 = 2*k
  k2p1 = k2 + 1
  do j = lo(2), hi(2)
    j2 = 2*j
    j2p1 = j2 + 1
    do i = lo(1), hi(1)
      i2 = 2*i
      i2p1 = i2 + 1
      c(i,j,k) =  (
$                 + f(i2p1,j2p1,k2  ) + f(i2,j2p1,k2  )
$                 + f(i2p1,j2  ,k2  ) + f(i2,j2  ,k2  )
$                 + f(i2p1,j2p1,k2p1) + f(i2,j2p1,k2p1)
$                 + f(i2p1,j2  ,k2p1) + f(i2,j2  ,k2p1)
$                 )*eighth
    end do
  end do
end do
```

where `f` is the field on the fine grid and `c` is the field on the coarse
grid. (This multigrid solver always coarsens grids by factors of two in each
dimension.) For each evaluation of a coarse grid point, the algorithm must load
8 values from the fine grid. However, there is significant memory locality in
this algorithm, as many of the fine grid points for coarse grid point
`c(i,j,k)` also contribute to the point `c(i+1,j,k)`.

## Prolongation

Prolongation (also called interpolation) is the opposite of restriction: one
approximates the value of a field on a coarse grid on a finer grid. The
prolongation kernel in the BoxLib solver is as follows:
```fortran
do k = lo(3), hi(3)
  k2 = 2*k
  k2p1 = k2 + 1
  do j = lo(2), hi(2)
    j2 = 2*j
    j2p1 = j2 + 1
    do i = lo(1), hi(1)
      i2 = 2*i
      i2p1 = i2 + 1

      f(i2p1,j2p1,k2  ) = c(i,j,k) + f(i2p1,j2p1,k2  )
      f(i2  ,j2p1,k2  ) = c(i,j,k) + f(i2  ,j2p1,k2  )
      f(i2p1,j2  ,k2  ) = c(i,j,k) + f(i2p1,j2  ,k2  )
      f(i2  ,j2  ,k2  ) = c(i,j,k) + f(i2  ,j2  ,k2  )
      f(i2p1,j2p1,k2p1) = c(i,j,k) + f(i2p1,j2p1,k2p1)
      f(i2  ,j2p1,k2p1) = c(i,j,k) + f(i2  ,j2p1,k2p1)
      f(i2p1,j2  ,k2p1) = c(i,j,k) + f(i2p1,j2  ,k2p1)
      f(i2  ,j2  ,k2p1) = c(i,j,k) + f(i2  ,j2  ,k2p1)

    end do
  end do
end do
```

In 3-D, the same value on the coarse grid contributes equally to eight
neighboring points in the fine grid. (The symmetry arises from the constraint
in the solver that the cells must be cubic.)

## Exact linear solve

The multigrid solver in BoxLib recursively coarsens grids until the grid
reaches a sufficiently small size, often $2^3$ if the problem domain is cubic.
On the coarsest grid, the solver then solves the linear system exactly, before
propagating the solution back up to finer grids.
