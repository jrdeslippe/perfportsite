# Geometric Multigrid

Many problems encountered in BoxLib applications require solutions to linear
system, e.g., [elliptic partial differential equations](https://en.wikipedia.org/wiki/Elliptic_partial_differential_equation) such as the [Poisson
equation](https://en.wikipedia.org/wiki/Poisson%27s_equation) for self-gravity, and the [diffusion equation](https://en.wikipedia.org/wiki/Diffusion_equation). BoxLib therefore
includes [geometric multigrid solvers](https://en.wikipedia.org/wiki/Multigrid_method) for solving problems which use both
cell-centered and nodal data. For this project, we have focused on the
cell-centered solver due to its relative simplicity compared to the nodal
solver.

Geometric multigrid is an iterative method for solving linear problems which
contains roughly 4 steps:

  * relaxation
  * restriction
  * prolongation
  * coarse-grid linear solve (either approximate or exact)

Although here we will not discuss the details of the geometric multigrid
method, we summarize each of these steps below as they pertain to computational
algorithms. Although these steps are algorithmically unique, we note that all
of them feature low arithmetic intensity and are thus sensitive to cache and
memory bandwidth.

## Relaxation

A relaxation consists of one or more iterations of an approximate solution to
the system of linear equations. In geometric multigrid, common algorithms used
here include Jacobi and Gauss-Seidel. By default, the BoxLib solver uses a
variation on Gauss-Seidel called Gauss-Seidel red-black ("GSRB"). GSRB deviates
from the original [Gauss-Seidel method](https://en.wikipedia.org/wiki/Gauss–Seidel_method) by exploiting a symmetry in the data
dependence among matrix elements, such that an update sweep of all matrix
elements follows a stride-2 pattern rather than stride-1. (This property
manifests in the innermost loop of the kernel shown below).

```fortran
do k = lo(3), hi(3)
  do j = lo(2), hi(2)
     ioff = MOD(lo(1) + j + k + redblack,2)
     do i = lo(1) + ioff,hi(1),2
        gamma = alpha*a(i,j,k) &
              +   dhx*(bX(i,j,k)+bX(i+1,j,k)) &
              +   dhy*(bY(i,j,k)+bY(i,j+1,k)) &
              +   dhz*(bZ(i,j,k)+bZ(i,j,k+1))

        g_m_d = gamma &
              - (dhx*(bX(i,j,k)*cf0 + bX(i+1,j,k)*cf3) &
              +  dhy*(bY(i,j,k)*cf1 + bY(i,j+1,k)*cf4) &
              +  dhz*(bZ(i,j,k)*cf2 + bZ(i,j,k+1)*cf5)) &

        rho = dhx*( bX(i  ,j,k)*phi(i-1,j,k) &
            +       bX(i+1,j,k)*phi(i+1,j,k) ) &
            + dhy*( bY(i,j  ,k)*phi(i,j-1,k) &
            +       bY(i,j+1,k)*phi(i,j+1,k) ) &
            + dhz*( bZ(i,j,k  )*phi(i,j,k-1) &
            +       bZ(i,j,k+1)*phi(i,j,k+1) ) &

        res =  rhs(i,j,k) - (gamma*phi(i,j,k) - rho)
        phi(i,j,k) = phi(i,j,k) + omega/g_m_d * res
     end do
  end do
end do
```

The algorithm above uses a 7-point cell-centered discretization of the 3-D
variable-coefficient Helmholtz operator. The diffusion operator is one type of
Helmholtz operator; the Laplace operator, which appears in the Poisson equation
for self-gravity, is a simplified version, with constant coefficients.

The GSRB method for a 7-point discretization of the Helmholtz operator exhibits
a low arithmetic intensity, requiring several non-contiguous loads from memory
to evaluate the operator.

The relaxation step and the coarse grid solve (discussed below) often feature
similar computational and data access patterns, because both are effectively
doing the same thing - solving a linear system. The primary difference between
them is that the relaxation method applies the iterative kernel only a handful
of times, whereas the coarse grid solve often iterates all the way to
convergence.

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
propagating the solution back up to finer grids. The solution algorithm chosen
for this step is rarely influential on the overall performance of the multigrid
algorithm, because the problem size at the coarsest grid is so small. In
BoxLib, the default coarse grid solver algorithm is [BiCGSTAB](https://en.wikipedia.org/wiki/Biconjugate_gradient_stabilized_method), a variation on
the conjugate-gradient iterative method.
