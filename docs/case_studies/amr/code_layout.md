## Code Layout

The typical form of a BoxLib application is a C++ "driver" code which manages
the boxes on the domain, and calls Fortran kernels in a loop over the boxes
owned by each MPI process. An example of this layout is shown below:

```c++
// Advance the solution one grid at a time
for ( MFIter mfi(old_phi); mfi.isValid(); ++mfi )
{
  const Box& bx = mfi.validbox();

  update_phi(old_phi[mfi].dataPtr(),
             new_phi[mfi].dataPtr(),
             &ng_p,
             flux[0][mfi].dataPtr(),
             flux[1][mfi].dataPtr(),
             flux[2][mfi].dataPtr(),
             &ng_f, bx.loVect(), bx.hiVect(), &dx[0], &dt);
  }
}
```

Here the `MFIter` object is an iterator over boxes owned by an MPI process. The
`Box` object contains the geometric metadata describing a particular box, e.g.,
the indices of the lower and upper corners. The variables `old_phi`, `new_phi`,
and `flux` contain pointers to the arrays which contain the floating point data
on the grid. The `update_phi` function is a Fortran function which uses the
data from the `Box` object to construct 3-D loops over the appropriate section
of the three floating-point arrays. The function may look like the following:

```fortran
subroutine update_phi(phiold, phinew, ng_p, fluxx, fluxy, fluxz, ng_f, lo, hi, dx, dt) bind(C, name="update_phi")

  integer          :: lo(3), hi(3), ng_p, ng_f
  double precision :: phiold(lo(1)-ng_p:hi(1)+ng_p,lo(2)-ng_p:hi(2)+ng_p,lo(3)-ng_p:hi(3)+ng_p)
  double precision :: phinew(lo(1)-ng_p:hi(1)+ng_p,lo(2)-ng_p:hi(2)+ng_p,lo(3)-ng_p:hi(3)+ng_p)
  double precision ::  fluxx(lo(1)-ng_f:hi(1)+ng_f+1,lo(2)-ng_f:hi(2)+ng_f,lo(3)-ng_f:hi(3)+ng_f)
  double precision ::  fluxy(lo(1)-ng_f:hi(1)+ng_f,lo(2)-ng_f:hi(2)+ng_f+1,lo(3)-ng_f:hi(3)+ng_f)
  double precision ::  fluxz(lo(1)-ng_f:hi(1)+ng_f,lo(2)-ng_f:hi(2)+ng_f,lo(3)-ng_f:hi(3)+ng_f+1)
  double precision :: dx, dt

  integer i,j,k

  do k=lo(3),hi(3)
     do j=lo(2),hi(2)
        do i=lo(1),hi(1)

           phinew(i,j,k) = phiold(i,j,k) + dt * &
                ( fluxx(i+1,j,k)-fluxx(i,j,k) &
                +fluxy(i,j+1,k)-fluxy(i,j,k) &
                +fluxz(i,j,k+1)-fluxz(i,j,k) ) / dx

        end do
     end do
  end do
```

The Fortran function constructs the appropriate "view" into each box using the
data from the `Box` object from the C++ function, as well as from the number of
ghost zones (`ng_p` for `old_phi` and `new_phi`, and `ng_f` for `flux`).

The above example demonstrates pure MPI parallelism; the analogous C++ code
which uses OpenMP tiling as described above would look like the following:

```c++
// Advance the solution one grid at a time
#ifdef _OPENMP
#pragma omp parallel
#endif
for ( MFIter mfi(old_phi,true); mfi.isValid(); ++mfi )
{
  const Box& tbx = mfi.tilebox();

  update_phi(old_phi[mfi].dataPtr(),
             new_phi[mfi].dataPtr(),
             &ng_p,
             flux[0][mfi].dataPtr(),
             flux[1][mfi].dataPtr(),
             flux[2][mfi].dataPtr(),
             &ng_f, tbx.loVect(), tbx.hiVect(), &dx[0], &dt);
  }
}
```

The OpenMP parallelism is coarse-grained; rather than constructing a large
`Box` from `mfi.validbox()`, it constructs a smaller `Box` from
`mfi.tilebox()`. The metadata format remains unchanged, allowing the Fortran
function to remain unchanged as well.
