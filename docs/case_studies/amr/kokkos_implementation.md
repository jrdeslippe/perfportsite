# Kokkos Implementation

This section is written as some kind of lab report, since we think that it illustrates best what challenges users might face when making complicated frameworks such as BoxLib performance portable.

## First Attempt

This section will describe our first, unfinished attempt, to port BoxLib over to Kokkos. The approach was designed to be the cleanest but also the most difficult one. We learned some lessons in the process which we want to share with the reader of this case study.

### Memory Management

In theory, one would like to make the data resident on the *device* all the time to avoid unnecessary data transfer. We thus implemented a ```KArenaND``` class which allows us to use Kokkos views instead of plain arrays for storing the data. This is the abstract, N-dimensional class which provides a part of the interface:

```C++
//generic ND template
template <typename T, int D>
class KArenaND {
public:
  //
  // Allocates a dynamic memory arena of size sz.
  // Returns a pointer to this memory.
  //
  virtual void* alloc (const std::vector<std::size_t>& _sz) = 0;
protected:
  virtual void free() = 0;
};
```

We then (partially) specialize this class in order generate a ```KArena3D```-variant, as this is what we mostly use in our code. This class is defined as

```C++
template <typename T>
class KArenaND<T,3> {
public:
  //
  // Allocates a dynamic memory arena of size sz.
  // Returns a pointer to this memory.
  //
  void* alloc (const std::vector<size_t>& sz_vec);
  
  // pass access operator through to simplify things
  T& operator()(int a0, int a1, int a2);
  const T& operator()(int a0, int a1, int a2) const;
  T& operator()(const IntVect& a);
  const T& operator()(const IntVect& a) const;
  
  // and return the view
  Kokkos::View<T***>& viewData(){ return view; }
private:
  void free();
  Kokkos::View<T***> view;
};
```

The corresponding allocator looks like then:

```C++
template<typename T>
void* KArenaND<T,3>::alloc (const std::vector<size_t>& _sz_vec)
{
  if(_sz_vec.size()!=3){
    BoxLib::Abort("Error, the vector size passed to KArenaND has to be equal to its dimension!");
  }
  
  // important: reverse dimensions for optimal access
  view = Kokkos::View<T***>("KArena_view3D",_sz_vec[2],_sz_vec[1],_sz_vec[0]);
  
  // provide interface compatibility with the rest of boxlib, but never use that pointer.
  return reinterpret_cast<void*>(view.ptr_on_device());
}
```

!!!warning
    When packing Views into classes, avoid using pointers and the ```new``` operator to instantiate a new View. **This pointer will be a host-only pointer and will have NULL value when accessed from a device which uses a different address space.** The reference counting is only guaranteed to work properly if the View is stored and passed by value. In that sense, also avoid passing references to views. Note that Kokkos::Views are lightweight objects so there is no performance reason to use pointers/references instead of values in this case.

We further implemented operators to access the memory, which basically pass the View access operator to the outside. For example:

```C++
template<typename T>
T& KArenaND<T,3>::operator()(int a0, int a1, int a2)
{
  // indices reversed compared to BoxLib
  // in roder to ensure interface compatibility
  return view(a2,a1,a0);
}
```

Note that we reverse the order of indices here. This is because BoxLib uses the indexing ```(x,y,z)``` whereas for Kokkos views it is more convenient if the order ```(z,y,x)``` is used so that one can use Kokkos default layouts, i.e. ```Layout::Left``` on GPU and ```Layout::Right``` on CPU. If one would use the BoxLib indexing on the view level, this logic would need to be inverted whenever a Kokkos parallel dispatch is used. Instead, we invert it on the access operator level so that we neither need to explicitly specify an iteration policy nor break the BoxLib indexing order in the rest of the code.

There are advantages and disadvantages to burying the Kokkos data containers deep into the framework. The obvious advantage is that once it works, basically the majority of the framework will already be Kokkos compatible. The disadvantage is that incremental porting is not possible, it is an all-or-nothing approach.

### Rewriting Fortran Kernels

A big difficulty with porting the BoxLib GMG to Kokkos is that most of the kernels are written in Fortran. For Kokkos, we need those kernels in C++ so we have started rewriting those kernels accordingly. As it turns out, the Kokkos GMG tutorial touches many of these Fortran kernels, and so we stopped after altering almost 10K lines of code in about 50 files. Below you find the comparison between the BoxLib master branch from which we started to the current state of the Kokkos port branch.

```
~/BoxLib> git diff --stat cpp_kernels_kokkos-views 

 Src/C_BaseLib/FArrayBox.H                            |    2 -
 Src/C_BaseLib/FabArray.H                             |    8 +-
 Src/C_BaseLib/IArrayBox.H                            |    1 -
 Src/C_BaseLib/KArena.H                               |  265 ---------
 Src/C_BaseLib/KBaseFab.H                             | 3615 -----------------------------------------------------------------------------------------------------------------
 Src/C_BaseLib/Looping.H                              |  770 +-----------------------
 Src/C_BaseLib/Make.package                           |    6 +-
 Src/C_BaseLib/MultiFabUtil.cpp                       |  284 +++++----
 Src/C_BaseLib/MultiFabUtil_3d.cpp                    |  247 --------
 Src/C_BaseLib/MultiFabUtil_F.H                       |    8 -
 Src/C_BoundaryLib/Mask.H                             |    1 -
 Src/C_BoundaryLib/Mask.cpp                           |    2 +-
 Src/LinearSolvers/C_CellMG/ABecLaplacian.H           |    9 +-
 Src/LinearSolvers/C_CellMG/ABecLaplacian.cpp         | 1119 ++++++++++++++++-------------------
 Src/LinearSolvers/C_CellMG/ABec_3D.F                 |    4 +-
 Src/LinearSolvers/C_CellMG/CGSolver.H                |    6 +-
 Src/LinearSolvers/C_CellMG/CGSolver.cpp              |   13 +-
 Src/LinearSolvers/C_CellMG/LO_3D_cpp.cpp             |  235 --------
 Src/LinearSolvers/C_CellMG/LO_F.H                    |    5 -
 Src/LinearSolvers/C_CellMG/Laplacian.H               |    3 +-
 Src/LinearSolvers/C_CellMG/Laplacian.cpp             |  343 ++++++-----
 Src/LinearSolvers/C_CellMG/LinOp.H                   |   12 +-
 Src/LinearSolvers/C_CellMG/LinOp.cpp                 |   85 +--
 Src/LinearSolvers/C_CellMG/MG_3D_cpp.cpp             |  464 ---------------
 Src/LinearSolvers/C_CellMG/MG_3D_fortran.F           |   96 ---
 Src/LinearSolvers/C_CellMG/MG_3D_old.cpp             |  222 -------
 Src/LinearSolvers/C_CellMG/MG_F.H                    |   81 ---
 Src/LinearSolvers/C_CellMG/Make.package              |    6 +-
 Src/LinearSolvers/C_CellMG/MultiGrid.H               |    4 +-
 Src/LinearSolvers/C_CellMG/MultiGrid.cpp             | 1463 +++++++++++++++++++++++-----------------------
 Src/LinearSolvers/C_CellMG/old/MG_3D_cpp.cpp-average |   39 --
 Src/LinearSolvers/C_CellMG4/ABec2.H                  |    5 +-
 Src/LinearSolvers/C_CellMG4/ABec4.H                  |    3 +-
 Src/LinearSolvers/C_CellMG4/ABec4.cpp                |    7 +-
 Tools/C_mk/Make.rules                                |    4 +-
 Tools/Postprocessing/F_Src/GNUmakefile               |    2 +-
 Tutorials/MultiGrid_C/COEF_3D.F90                    |   14 +-
 Tutorials/MultiGrid_C/COEF_F.H                       |   10 +-
 Tutorials/MultiGrid_C/GNUmakefile                    |   28 +-
 Tutorials/MultiGrid_C/KokkosCore_config.h            |   11 -
 Tutorials/MultiGrid_C/KokkosCore_config.tmp          |   11 -
 Tutorials/MultiGrid_C/MG_helpers_cpp.cpp             |  162 ------
 Tutorials/MultiGrid_C/Make.package                   |    2 +-
 Tutorials/MultiGrid_C/RHS_3D.F90                     |  143 ++---
 Tutorials/MultiGrid_C/RHS_F.H                        |    3 +-
 Tutorials/MultiGrid_C/fcompare                       |  Bin 3475616 -> 0 bytes
 Tutorials/MultiGrid_C/inputs                         |    6 +-
 Tutorials/MultiGrid_C/main.cpp                       | 1530 ++++++++++++++++++++++++------------------------
 Tutorials/MultiGrid_C/out-F                          |  522 -----------------
 Tutorials/MultiGrid_C/out-cpp                        |  522 -----------------
 55 files changed, 2455 insertions(+), 10764 deletions(-)
```

Clearly, this is a major endeavor and we stopped our explorations for the moment at this point. 
Furthermore, it is not clear what performance Kokkos can deliver for the tasks at hand. To assess that, we abandoned the full port and continued with a partial port described below.

## Second Attempt
Since porting the full application is a major effort but we still want to assess Kokkos' potential for BoxLib, we followed a different strategy in this attempt: we will port all performance relevant GMG kernels to Kokkos, copying data into a suitable view before calling the kernel, then using Kokkos' parallel dispatcher to launch the kernels, and then fill the results back into BoxLib's own ```BaseFab``` datatype. 
It is important to note that BoxLib uses offsets in the array-indexing and those can be different for different fields (e.g. some fields have ghost zones and some do not).

We thus decided to encapsulate this complexity into a new class. Below we show the declaration of the one specialized for ```FArraBox``` datatypes, i.e. ```BaseFab``` instances with types ```Real```.

```C++
template<>
class ViewFab<Real> {
public:

  // swap indices here to get kokkos'-canonical layout
  KOKKOS_INLINE_FUNCTION
  Real& operator()(const int& i, const int& j, const int& k, const int& n = 0){
    return data(n, k-smallend[2], j-smallend[1], i-smallend[0]);
  }

  KOKKOS_INLINE_FUNCTION
  Real& operator()(const int& i, const int& j, const int& k, const int& n = 0) const {
      return data(n, k-smallend[2], j-smallend[1], i-smallend[0]);
  }

  void init(const FArrayBox& rhs_, const std::string& name_);

  ViewFab(){}

  ViewFab(const FArrayBox& rhs_, const std::string& name_){
      init(rhs_,name_);
  }

  ViewFab<Real>& operator=(const ViewFab<Real>& rhs_);
  
  // write the view data into a FArrayBox
  void fill(FArrayBox& lhs_) const;
private:
  std::string name;
  int numvars;
  IntVect smallend, bigend, length;
  Kokkos::View<Real****> data;
};
```

The important aspect is that the access operator hides the offset indexing and thus keeps the kernels clean.
Note that this class is similar to what we try to use in our first attempt, but this time we do not bury it deep into the Framework but rather only use it for making the individual kernels performance portable. The access operators need to be decorated with ```KOKKOS_INLINE_FUNCTION``` macros because they will be called from the device. In order to copy relevant *metadata* to the device, we use the functor approach. That means we pack all relevant parameters into a functor object and then provide an access operator to it. For example, the average (restriction) functor is

```C++
struct C_AVERAGE_FUNCTOR{
public:
  C_AVERAGE_FUNCTOR(const FArrayBox& c_, const FArrayBox& f_) : cv(c_,"cv"), fv(f_,"fv"){
    cv.syncH2D();
    fv.syncH2D();
  }

  KOKKOS_INLINE_FUNCTION
  void operator()(const int n, const int k, const int j, const int i) const{
    cv(i,j,k,n) =  (fv(2*i+1,2*j+1,2*k,n) + fv(2*i,2*j+1,2*k,n) + fv(2*i+1,2*j,2*k,n) + fv(2*i,2*j,2*k,n))*0.125;
    cv(i,j,k,n) += (fv(2*i+1,2*j+1,2*k+1,n) + fv(2*i,2*j+1,2*k+1,n) + fv(2*i+1,2*j,2*k+1,n) + fv(2*i,2*j,2*k+1,n))*0.125;
  }

  void fill(FArrayBox& cfab){
    cv.syncD2H();
    cv.fill(cfab);
  }
private:
  ViewFab<Real> cv, fv;
};
```

It contains the two viewfabs needed and makes sure that data is uploaded to and downloaded from the device when needed. The average-kernel then simply becomes:

```C++
void C_AVERAGE(
const Box& bx,
const int nc,
FArrayBox& c,
const FArrayBox& f){
	
  const int *lo = bx.loVect();
  const int *hi = bx.hiVect();
  const int* cb = bx.cbVect();
	
  // create functor
  C_AVERAGE_FUNCTOR cavfunc(c,f);
    
  // define policy
  typedef Kokkos::Experimental::MDRangePolicy<Kokkos::Experimental::Rank<4> > t_policy;

  // execute
  Kokkos::Experimental::md_parallel_for(t_policy({0, lo[2], lo[1], lo[0]},{nc, hi[2]+1, hi[1]+1, hi[0]+1},{nc, cb[2], cb[1], cb[0]}),cavfunc);

  // write back
  cavfunc.fill(c);
}
```

In order to employ loop-collapsing and additional cache blocking, we use the experimental multi-dimensional iteration policy feature. We added a cache-block-sizes vector ```cb``` which can be specified in the input file passed to the application. Most kernels can be ported like the one in the above example. The GSRB kernel though has non-unit stride access in the ```i``` loop, because of the red-black iteration pattern. For this case, we pass half of the actual range to the iteration policy and expand the index inside the loop. The access operator of the corresponding functor becomes

```C++
struct C_GSRB_FUNCTOR{
public:
  ...
  
  KOKKOS_INLINE_FUNCTION
  void operator()(const int n, const int k, const int j, const int ii) const{

    int ioff = (lo0 + j + k + rb) % 2;
    int i = 2 * (ii-lo0) + lo0 + ioff;
      
    //be careful to not run over
    if(i<=hi0){

      // boundary condition terms
      Real cf0 = ( (i==blo[0]) && (m0v(blo[0]-1,j,k)>0) ? f0v(blo[0],j,k) : 0. );
      Real cf1 = ( (j==blo[1]) && (m1v(i,blo[1]-1,k)>0) ? f1v(i,blo[1],k) : 0. );
      Real cf2 = ( (k==blo[2]) && (m2v(i,j,blo[2]-1)>0) ? f2v(i,j,blo[2]) : 0. );
      Real cf3 = ( (i==bhi[0]) && (m3v(bhi[0]+1,j,k)>0) ? f3v(bhi[0],j,k) : 0. );
      Real cf4 = ( (j==bhi[1]) && (m4v(i,bhi[1]+1,k)>0) ? f4v(i,bhi[1],k) : 0. );
      Real cf5 = ( (k==bhi[2]) && (m5v(i,j,bhi[2]+1)>0) ? f5v(i,j,bhi[2]) : 0. );

      // assign overrelaxation constants
      double gamma =  alpha * av(i,j,k)
                    + dhx * (bXv(i,j,k) + bXv(i+1,j,k))
                    + dhy * (bYv(i,j,k) + bYv(i,j+1,k))
                    + dhz * (bZv(i,j,k) + bZv(i,j,k+1));

      double g_m_d =  gamma
                    - dhx * (bXv(i,j,k)*cf0 + bXv(i+1,j,k)*cf3)
                    - dhy * (bYv(i,j,k)*cf1 + bYv(i,j+1,k)*cf4)
                    - dhz * (bZv(i,j,k)*cf2 + bZv(i,j,k+1)*cf5);

      double rho =  dhx * (bXv(i,j,k)*phiv(i-1,j,k,n) + bXv(i+1,j,k)*phiv(i+1,j,k,n))
                  + dhy * (bYv(i,j,k)*phiv(i,j-1,k,n) + bYv(i,j+1,k)*phiv(i,j+1,k,n))
                  + dhz * (bZv(i,j,k)*phiv(i,j,k-1,n) + bZv(i,j,k+1)*phiv(i,j,k+1,n));

      double res = rhsv(i,j,k,n) - gamma * phiv(i,j,k,n) + rho;
      phiv(i,j,k,n) += omega/g_m_d * res;
    }
  }

  ...
};
```

Note that we still have to avoid running over array bounds. That can occur when the grid extent in ```i```-direction is odd. The iteration policy now becomes

```C++
// instantiate functor
C_GSRB_FUNCTOR cgsrbfunc(bx, bbx, rb, alpha, beta, phi, rhs, a, bX, bY, bZ, f0, m0, f1, m1, f2, m2, f3, m3, f4, m4, f5, m5, h);

// compute bounds used in i-iteration
int length0 = std::floor( (hi[0]-lo[0]+1) / 2 );
int up0 = lo[0] + length0;

// dispatch kernel
Kokkos::Experimental::md_parallel_for(t_policy({0, lo[2], lo[1], lo[0]}, {nc, hi[2]+1, hi[1]+1, up0+1}, {nc, cb[2], cb[1], length0}), cgsrbfunc);
```

We experimented with including the full loop over ```i``` into our iteration policy and then skipping the iteration if ```(i + j + k) % 2 != 0```, but that decreased performance on the CPU by more than 50%. In general, it would be good if Kokkos' range policies allow for strided iterations.

The above approach clearly comes with data transfer overhead which we would have avoided if we would have followed through our first attempt. However, in the performance timings we will report later on, we explicitly exclude that overhead and just assess the run time of the kernels themselves. That way, we can determine if Kokkos is a viable framework for ensuring performance portability of BoxLib across architectures.