# Code Structure

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

# Memory Management

BoxLib abstracts the memory management by using the abstract ```Arena``` class.

```C++
#ifndef BL_ARENA_H
#define BL_ARENA_H

#include <winstd.H>
#include <cstddef>

class Arena;

namespace BoxLib
{
    Arena* The_Arena ();
}

//
// A Virtual Base Class for Dynamic Memory Management
//
// This is a virtual base class for objects that manage their own dynamic
// memory allocation.  Since it is a virtual base class, you have to derive
// something from it to use it.
//

class Arena
{
public:

    virtual ~Arena ();
    //
    // Allocate a dynamic memory arena of size sz.
    // A pointer to this memory should be returned.
    //
    virtual void* alloc (std::size_t sz) = 0;
    //
    // A pure virtual function for deleting the arena pointed to by pt.
    //
    virtual void free (void* pt) = 0;
    //
    // Given a minimum required arena size of sz bytes, this returns
    // the next largest arena size that will align to align_size bytes.
    //
    static std::size_t align (std::size_t sz);

protected:

    static const unsigned int align_size = 16;
};

#endif /*BL_ARENA_H*/
```
The most general container class in BoxLib, the ```BaseFab```, calls the ```Arena``` data allocator to allocate its memory. Therefore, by providing a specialized Arena-descendant, the user can easily plug in his own data containers or decorate his allocations with alignment or memory placing directives.

# C++ Kernel Rewrites

Some programming models do not support Fortran and thus for using those, we need to port our kernels to C++. Below we show the ported GSRB kernel. For the sake of simplicity, we work directly with the fabs and not with the data pointers as we do in Fortran, so that we can use the access operator to index into our data containers. 

```C++
void C_GSRB_3D(
const Box& bx,
const Box& bbx,
const int nc,
const int rb,
const Real alpha,
const Real beta,
FArrayBox& phi,
const FArrayBox& rhs,
const FArrayBox& a,
const FArrayBox& bX,
const FArrayBox& bY,
const FArrayBox& bZ,
const FArrayBox& f0,
const Mask& m0,
const FArrayBox& f1,
const Mask& m1,
const FArrayBox& f2,
const Mask& m2,
const FArrayBox& f3,
const Mask& m3,
const FArrayBox& f4,
const Mask& m4,
const FArrayBox& f5,
const Mask& m5,
const Real* h)
{
	//box extends:
	const int *lo = bx.loVect();
	const int *hi = bx.hiVect();
	//blo
	const int *blo = bbx.loVect();
	const int *bhi = bbx.hiVect();
	
	//some parameters
	Real omega= 1.15;
	Real dhx = beta/(h[0]*h[0]);
	Real dhy = beta/(h[1]*h[1]);
	Real dhz = beta/(h[2]*h[2]);
	
	for (int n = 0; n<nc; n++){
		for (int k = lo[2]; k <= hi[2]; ++k) {
			for (int j = lo[1]; j <= hi[1]; ++j) {
				int ioff = (lo[0] + j + k + rb)%2;
				for (int i = lo[0] + ioff; i <= hi[0]; i+=2) {
					
					//BC terms
					Real cf0 = ( (i==blo[0]) && (m0(IntVect(blo[0]-1,j,k))>0) ? f0(IntVect(blo[0],j,k)) : 0. );
					Real cf1 = ( (j==blo[1]) && (m1(IntVect(i,blo[1]-1,k))>0) ? f1(IntVect(i,blo[1],k)) : 0. );
					Real cf2 = ( (k==blo[2]) && (m2(IntVect(i,j,blo[2]-1))>0) ? f2(IntVect(i,j,blo[2])) : 0. );
					Real cf3 = ( (i==bhi[0]) && (m3(IntVect(bhi[0]+1,j,k))>0) ? f3(IntVect(bhi[0],j,k)) : 0. );
					Real cf4 = ( (j==bhi[1]) && (m4(IntVect(i,bhi[1]+1,k))>0) ? f4(IntVect(i,bhi[1],k)) : 0. );
					Real cf5 = ( (k==bhi[2]) && (m5(IntVect(i,j,bhi[2]+1))>0) ? f5(IntVect(i,j,bhi[2])) : 0. );
					
					//assign ORA constants
					double gamma = alpha * a(IntVect(i,j,k))
									+ dhx * (bX(IntVect(i,j,k)) + bX(IntVect(i+1,j,k)))
									+ dhy * (bY(IntVect(i,j,k)) + bY(IntVect(i,j+1,k)))
									+ dhz * (bZ(IntVect(i,j,k)) + bZ(IntVect(i,j,k+1)));
					
					double g_m_d = gamma
									- dhx * (bX(IntVect(i,j,k))*cf0 + bX(IntVect(i+1,j,k))*cf3)
									- dhy * (bY(IntVect(i,j,k))*cf1 + bY(IntVect(i,j+1,k))*cf4)
									- dhz * (bZ(IntVect(i,j,k))*cf2 + bZ(IntVect(i,j,k+1))*cf5);
					
					double rho =  dhx * (bX(IntVect(i,j,k))*phi(IntVect(i-1,j,k),n) + bX(IntVect(i+1,j,k))*phi(IntVect(i+1,j,k),n))
								+ dhy * (bY(IntVect(i,j,k))*phi(IntVect(i,j-1,k),n) + bY(IntVect(i,j+1,k))*phi(IntVect(i,j+1,k),n))
								+ dhz * (bZ(IntVect(i,j,k))*phi(IntVect(i,j,k-1),n) + bZ(IntVect(i,j,k+1))*phi(IntVect(i,j,k+1),n));
					
					double res = rhs(IntVect(i,j,k),n) - gamma * phi(IntVect(i,j,k),n) + rho;
					phi(IntVect(i,j,k),n) += omega/g_m_d * res;
				}
			}
		}
	}
}
```

We try to avoid porting all Fortran kernels for our explorations but some of the frameworks would basically require that. We will make comments about this in appropriate places.