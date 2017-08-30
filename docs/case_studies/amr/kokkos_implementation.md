# Kokkos Implementation

This section is written as some kind of lab report, since we think that it illustrates best what challenges users might face when making complicated frameworks such as BoxLib performance portable.


## Memory Management

Kokkos provides the ```Kokkos::View``` class for managing data and providing accessors to array elements, slicing etc.. The advantage is that the user does not need to know how the data is stored under the hood, i.e. if it is aligned, padded, strided, etc.. However, this approach also requires the user to only use the provided accessor functions to access the data or runtime errors might occur. One method to circumvent this problem are *unmanaged views*: here, the user allocates an array the regular way and defines a view on top of that. This approach is goo for incremental porting as it does not break existing functionality, but comes with certain disadvantages we will discuss below. Another difficulty is that ```Kokkos::Views```, managed or unmanaged, do not support offset or negative indexing but those type of indexing is used frequently in BoxLib. We worked around this by implementing a small, lightweight ```ViewFab``` class:

```C++
// some useful typedefs and aliases
// this is always unmanaged
template<typename T>
using hostview = Kokkos::View<T, Kokkos::LayoutLeft, Kokkos::HostSpace, Kokkos::MemoryUnmanaged>;
#ifdef KOKKOS_ENABLE_CUDA
// device view is a managed CUDA-view
template<typename T>
using devview = Kokkos::View<T, Kokkos::LayoutLeft, Kokkos::CudaSpace>;
#else
//device view is a managed host-view
template<typename T>
using devview = Kokkos::View<T, Kokkos::LayoutLeft, Kokkos::HostSpace>;
#endif

// a small class for wrapping kokkos views nicely
template <typename T>
class ViewFab {
public:

#if BL_SPACEDIM == 3
  hostview<T****> h_data;
  devview<T****> d_data;
  // access operator
  KOKKOS_FORCEINLINE_FUNCTION
  T& operator()(const int i, const int j, const int k, const int n = 0) const {
    return d_data(i-smallend[0], j-smallend[1], k-smallend[2], n);
  }
#else
#error "ViewFab only supports 3D!";
#endif
  int smallend[BL_SPACEDIM + 1];

  void syncH2D(){
    Kokkos::deep_copy(d_data,h_data);
  }

  void syncD2H(){
    Kokkos::deep_copy(h_data,d_data);
  }

};
```

This class could trivially be implemented for any dimension but we restricted ourselves to the interesting three dimensional case. We also wrapped up- and download functions in order to facilitate host-device-synchronization. In order to provide backwards compatibility, it is important that both layouts, i.e. for device and host, match BoxLibs column-order layout. 
We then embedded this class into BoxLibs main data container ```BaseFab```:

```C++
template <class T>
class BaseFab
{
public:

  ...
  
  ViewFab<T> view_fab;
};
```

All what is left to do is to define the view inside the ```BaseFab``` allocator function:

```C++
aseFab<T>::define ()
{
  
  // This is the standard BoxLib allocator
  BL_ASSERT(nvar > 0);
  BL_ASSERT(dptr == 0);
  BL_ASSERT(numpts > 0);
  BL_ASSERT(std::numeric_limits<long>::max()/nvar > numpts);
  
  truesize  = nvar*numpts;
  dptr      = static_cast<T*>(BoxLib::The_Arena()->alloc(truesize*sizeof(T)));
  ptr_owner = true;
  //
  // Now call T::T() on the raw memory so we have valid Ts.
  //
  T* ptr = dptr;
  //
  // Note this must be long not int for very large (e.g.,1024^3) boxes.
  //
  for (long i = 0; i < truesize; i++, ptr++)
  {
    new (ptr) T;
  }

  // This is the View construction
  {
    //copy offset
    for (int d = 0; d < BL_SPACEDIM; ++d){
      view_fab.smallend[d]=smallEnd()[d];
    }
    view_fab.smallend[BL_SPACEDIM]=0;

    // create host view
#if BL_SPACEDIM == 3
    view_fab.h_data = hostview<T****>(const_cast<T*>(dataPtr()), 
                                      length()[0], 
                                      length()[1], 
                                      length()[2], 
                                      nComp());
    view_fab.d_data = devview<T****>(Kokkos::ViewAllocateWithoutInitializing("BoxLib"), 
                                     length()[0], 
                                     length()[1], 
                                     length()[2], 
                                     nComp());
#else
#error "ViewFab construction only supports 3D!";
#endif
  }

  BoxLib::update_fab_stats(numpts, truesize, sizeof(T));
}
```

Note that we do not need to initialize the device data to zero because we will do that on the host and upload the data before we are going to use it on the device. 
This construct allows us to use Kokkos parallel dispatchers which work on the embedded ```ViewFab``` as well as the conventional BoxLib kernels working with raw data pointers ```ptr```. We only need to make sure to synchronize data between host and device before using them on either one. 

!!!warning
	Our current implementation relies on either having the same data layout on host and device or on ```Kokkos::deep_copy``` being aware of possibile differences between data layouts. For example, the unmanaged view is unpadded but in theory a managed view could be padded. Since the device view is a managed view, a data transfer routine for synchronizing device and host memory needs to be aware of that. The current state of Kokkos is that ```Kokkos::deep_copy``` is not aware of these things but also managed views are never padded. As long as this does not change, our approach is safe. However, it implicitly assumes knowledge about how Kokkos stores the data which is not optimal. In any case, we found that this is the only way to enable incremental code porting with Kokkos. 


## Kernel Implementation

By implementing the memory management into the base container class, we make sure that all obejcts we are going to deal with have a view associated with it. The next step is to rewrite all kernels involved in the multigrid cycle. Although some of the kernels might not benefit from GPU acceleration, we nervetheless want to execute them on the device in order to avoid costly data copies. The example below shows out Kokkos implementation for the restriction kernel (average). 

```C++
template <int dim>
using mdpolicy = Kokkos::Experimental::MDRangePolicy<
                              Kokkos::Experimental::Rank<dim, outer_iter_policy, inner_iter_policy>, 
                              Kokkos::IndexType<int> >;

// Average Functor
struct C_AVERAGE_FUNCTOR{
public:
  C_AVERAGE_FUNCTOR(const FArrayBox& c_, const FArrayBox& f_) 
  : cv(c_.view_fab), fv(f_.view_fab) {}

  KOKKOS_FORCEINLINE_FUNCTION
  void operator()(const int i, const int j, const int k, const int n) const{
    cv(i,j,k,n) =  (fv(2*i+1,2*j+1,2*k,n) + fv(2*i,2*j+1,2*k,n) + fv(2*i+1,2*j,2*k,n) + fv(2*i,2*j,2*k,n))*0.125;
    cv(i,j,k,n) += (fv(2*i+1,2*j+1,2*k+1,n) + fv(2*i,2*j+1,2*k+1,n) + fv(2*i+1,2*j,2*k+1,n) + fv(2*i,2*j,2*k+1,n))*0.125;
  }

private:
  ViewFab<Real> cv, fv;
};

//Average Kernel
void C_AVERAGE(
  const Box& bx,
  const int nc,
  FArrayBox& c,
  const FArrayBox& f)
{
  const int *lo = bx.loVect();
  const int *hi = bx.hiVect();
  const int* cb = bx.cbVect();

  // create functor
  C_AVERAGE_FUNCTOR cavfunc(c,f);

  // execute functor
  Kokkos::Experimental::md_parallel_for(mdpolicy<4>({lo[0], lo[1], lo[2], 0}, 
                                                    {hi[0]+1, hi[1]+1, hi[2]+1, nc}, 
                                                    {cb[0], cb[1], cb[2], nc}), cavfunc);
}
```

We ported about 40 kernels in similar but straightforward fashion. The most effort here went into porting these kernels from Fortran to C++ since Kokkos does not work natively with Fortran. Once the C++-versions of the kernels were implemented and tested, applying Kokkos dispatchers to those is uncomplicated and relatively quick. 
In case of the GSRB kernel we had to work around the limitation that the innermost loop does not have stride-1 access because of the checkerboarding and Kokkos does not support that kind of access yet. We circumvented that issue by making the loop canonical, i.e. dividing the tripcount by two and expanding the innermost index accordingly inside the kernel: the code below shows how the dispatcher was implemented:

```C++
int length0 = std::floor( (hi[0]-lo[0]+1) / 2 );
int up0 = lo[0] + length0;
Kokkos::Experimental::md_parallel_for(mdpolicy<4>({lo[0], lo[1], lo[2], 0}, 
                                                  {up0+1, hi[1]+1, hi[2]+1, nc}, 
                                                  {cb[0], cb[1], cb[2], nc}), 
                                                  cgsrbfunc);
```

and below is the index expansion inside the loop body:

```C++
KOKKOS_FORCEINLINE_FUNCTION
void operator()(const int ii, const int j, const int k, const int n) const{
  int ioff = (lo0 + j + k + rb) % 2;
  int i = 2 * (ii-lo0) + lo0 + ioff;

  // if the i-dimension is odd, we could still run over, so better check
  if(i<=hi0){

    // kernel body

    ...
  }
}
```

The ```MDRangePolicy``` policy is very useful as it is able to collapse loops, apply cache blocking and improve vectorization at the same time. We control the cacheblock sizes for each dimension ```cb[i]``` with corresponding lines in the input file.

## Summary
Porting the BoxLib GMG to Kokkos is not trivial because of the plethora of Fortran kernels. One should be aware of this if one aims at making a legacy Fortran code performance portable. Also, incremental porting with Kokkos is doable but one has to use unmanaged views or use raw data pointers of managed views. Both is, according to the user manual, not recommended because the user makes underlying assumptions on the internal data layout. However, within a short amount of time, we were able to port the BoxLib GMG solver and all involved routines to Kokkos and achieved [satisfying performance](./performance_comparison.md).