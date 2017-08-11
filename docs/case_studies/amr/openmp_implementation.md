# Porting BoxLib to OpenMP 4.x

Since version 4.0, OpenMP has supported accelerator devices through data
offloading and kernel execution semantics. OpenMP presents an appealing
opportunity to achieve performance portability, as it requires fairly
non-invasive code modifications through directives which are ignored as
comments if OpenMP is not activated during compilation.

BoxLib already contains a large amount of OpenMP in the C++ framework to
implement thread parallelization and loop tiling (see [here](./parallelism.md)
and [here](./code_layout.md) for more details). However, these directives are
limited to version 3.0 and older, and consist primarily of multi-threading of
loops, such that the Fortran kernel execution happens entirely within a
thread-private region. This approach yields high performance on self-hosted
systems such as Intel Xeon and Xeon Phi, but provides no support for
architectures featuring a discrete accelerator such as a GPU.

We implemented the OpenMP `target` construct in several of the geometric
multigrid kernels in BoxLib in order to support kernel execution on GPUs. The
most minimal approach to the `target` directive is simply to decorate a loop
with `target` and `map` to move the data back and forth between host and device
during execution of the loop (see, e.g.,
[here](../../../perfport/directives/openmp#omp-target)). However, this will
often lead to slow code execution, especially if the loop is encountered
multiple times, as the data must migrate back and forth between host and device
each time the loop is executed.

A more optimized approach is to allocate the data on the device prior to look
execution, such that it need not re-allocate it each time the loop executes
(any updated values of the data will still need to be updated on the device).
This can be done with the `target enter data` and `target exit data`
constructs, introduced in OpenMP 4.5. In BoxLib, we accomplished this by
overloading the default data container `Arena` (see
[here](./code_structure#memory-management)) with a new `OMPArena` class which
invokes `omp target enter data` as soon as the memory is allocated. This
ensures that all FABs will be resident in device memory, obviating the need to
migrate all data in a loop back and forth between host and device:

```C++
void*
OMPArena::alloc (std::size_t _sz)
{
  void* pt=::operator new(_sz);
  char* ptr=reinterpret_cast<char*>(pt);
#pragma omp target enter data map(alloc:ptr[0:_sz])
  return pt;
}

void
OMPArena::free (void* pt)
{
  char* ptr=reinterpret_cast<char*>(pt);
#pragma omp target exit data map(release:ptr[:0])
    ::operator delete(pt);
}
```

We also modified some existing macros in BoxLib which characterize loop-level
parallelism. In these directives we implemented the `target` construct, e.g.,:

```C++
#define ForAllThisCPencilAdd(T,b,ns,nc,red)                             \
{                                                                       \
    BL_ASSERT(contains(b));                                             \
    BL_ASSERT((ns) >= 0 && (ns) + (nc) <= nComp());                     \
    const int *_th_plo = loVect();                                      \
    const int *_th_plen = length();                                     \
    const int *_b_lo = (b).loVect();                                    \
    IntVect b_length = (b).size();                                      \
    const int *_b_len = b_length.getVect();                             \
    const T* _th_p = dptr;                                              \
    const int _ns = (ns);                                               \
    const int _nc = (nc);                                               \
    T redR = (red);                                                     \
    _Pragma("omp target update to(_th_p[_ns*_th_plen[2]:(_ns+_nc)*_th_plen[2]])") \
    _Pragma("omp target data map(tofrom: redR) map(to: _nc, _ns, _th_plo[0:3], _th_plen[0:3], _b_len[0:3], _b_lo[0:3])") \
    _Pragma("omp target if(1)")                                         \
    {                                                                   \
    _Pragma("omp teams distribute parallel for collapse(3) reduction(+:redR)") \
    for(int _n = _ns; _n < _ns+_nc; ++_n) {                             \
        for(int _k = 0; _k < _b_len[2]; ++_k) {                         \
            for(int _j = 0; _j < _b_len[1]; ++_j) {                     \
                int nR = _n; nR += 0;                                   \
                const int jR = _j + _b_lo[1];                           \
                const int kR = _k + _b_lo[2];                           \
                const T *_th_pp = _th_p                                 \
                    + ((_b_lo[0] - _th_plo[0])                          \
                       + _th_plen[0]*(                                  \
                           (jR - _th_plo[1])                            \
                           + _th_plen[1]*(                              \
                               (kR - _th_plo[2])                        \
                               + _n * _th_plen[2])));                   \
                for(int _i = 0; _i < _b_len[0]; ++_i){                  \
                    const int iR = _i + _b_lo[0];                       \
                    const T &thisR = _th_pp[_i];
```

After this, one can add the `target teams distribute parallel for` construct to
many loops, moving to the device only the data which has changed since the
previous time the loop was executed. This can be done with the `update`
construct. For example, the restriction kernel in the multigrid solver becomes:

```C++
 subroutine FORT_AVERAGE (
$     c, DIMS(c),
$     f, DIMS(f),
$     lo, hi, nc)
     implicit none
     integer nc
     integer DIMDEC(c)
     integer DIMDEC(f)
     integer lo(BL_SPACEDIM)
     integer hi(BL_SPACEDIM)
     REAL_T f(DIMV(f),nc)
     REAL_T c(DIMV(c),nc)

     integer i, i2, i2p1, j, j2, j2p1, k, k2, k2p1, n

     !$omp target update to(f)

     !$omp target map(c, f) map(to: hi, lo)
     !$omp teams distribute parallel do simd collapse(4)
     !&omp private(n,k,j,i, k2,j2,i2, k2p1, j2p1,i2p1)
     do n = 1, nc
        do k = lo(3), hi(3)
           do j = lo(2), hi(2)
               do i = lo(1), hi(1)
                  k2 = 2*k
                  k2p1 = k2 + 1
                  j2 = 2*j
                  j2p1 = j2 + 1
                  i2 = 2*i
                  i2p1 = i2 + 1
                  c(i,j,k,n) =  (
$                     + f(i2p1,j2p1,k2  ,n) + f(i2,j2p1,k2  ,n)
$                     + f(i2p1,j2  ,k2  ,n) + f(i2,j2  ,k2  ,n)
$                     + f(i2p1,j2p1,k2p1,n) + f(i2,j2p1,k2p1,n)
$                     + f(i2p1,j2  ,k2p1,n) + f(i2,j2  ,k2p1,n)
$                     )*eighth
               end do
           end do
        end do
     end do
     !$omp end teams distribute parallel do simd
     !$omp end target
 end
```

Note that only `f`, which contains the fine grid data, needs to be updated on
the GPU before the loop begins. (This is because a few auxiliary functions
modify the finest grids which were not ported to the device, and so the finest
grid was updated on the host.) After the loop finishes, none of the data moves
off the device, since the fine grid `f` and the coarse grid `c` are not changed
on the host before the next kernel which requires this data executes on the
device. The only data which must be mapped to the device (but not mapped back)
are the `lo` and `hi` bounds of the loop indices.
