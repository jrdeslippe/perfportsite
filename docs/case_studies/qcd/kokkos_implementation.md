# Kokkos Implementation

In this implementation, we will use the ```Kokkos::View``` type as our data container. Therefore, the [spinor and gaugefield classes](./code_structure.md#Data_Primitives) become

```C++
template<typename ST,int nspin> 
class CBSpinor {
public: 
    ...
private:
    // dims are: site, color, spin
    Kokkos::View<ST*[3][nspin]> data;
};

template<typename GT> 
class CBGaugeField {
public:
    ...
private:
    // dims are: site, direction, color, color
    gauge_container<GT*[4][3][3]> data;
};
```

Note that the site index dimension is a runtime dimension (denoted by ```*```) whereas the other dimensions - color and spin - are fixed (denoted by ```[const]```). Explicitly stating this is recommended by the kokkos developers because it should help the compiler to optimize the code. 

In the [Wilsion operator class](./code_structure.md#wilson_operator), all what we need to do is to insert the kokkos parallel dispatcher. Hence it becomes

```C++
template<typename GT, typename ST, typename TST>
class Dslash {
    public:
    void operator(const CBSpinor<ST,4>& s_in,
                  const CBGaugeField<GT>& g_in,
                  CBSpinor<ST,4>& s_out,
                  int plus_minus) 
    {
        // Threaded loop over sites
        Kokkos::parallel_for(num_sites, KOKKOS_LAMBDA(int i) {
            ...
            });
    }
};
```
## Ensuring Vectorization
Vectorization in Kokkos is achieved by a two-level [nested parallelism](../../perfport/models/kokkos.md#vectorization), where the outer loop spawns threads (pthreads, OpenMP-threads) on the CPU and threads in CUDA-block y-direction on the GPU. The inner loop then applies vectorization pragmas on the CPU or spwans threads in x-direction on the GPU. This is where we have to show some awareness of architectural differences: the spinor work type ```TST``` needs to be a scalar type on the GPU and a vector type on the CPU. Hence we declare the following types on GPU and CPU respectively

```C++
template<typename T,N> 
struct CPUSIMDComplex {
    Kokkos::complex<T> _data[N];
    T& operator()(int lane) {
        return _data[lane];
    }
    ...
};

template<typename T,N> 
struct GPUSIMDComplex {
    Kokkos::complex<T> _data;
    T& operator()(int lane) {
        return _data;
    }
    ...
};
```

The latter construct might look confusing first, because the access operator ignores the ```lane``` parameter. This is because the SIMT threading is implicit in Kokkos and each SIMT thread is holding it's own data ```_data```. Nevertheless, it is useful to implement the access operator that way to preserve a common, portable style throughout the rest of the code.

In theory, these two types are sufficient for ensuring proper vectorization on both CPU and GPU. In our experiments however, we found that neither Intel nor GNU compiler could vectorize the complex operations inside the spinors properly, leading to a very poor performance. This is not a problem of Kokkos itself, it is merely the inability of compilers to efficiently vectorized complex algebra. We therefore provided a template  specialization for the ```CPUSIMDComplex``` datatype which we implemented by explicitly using AVX512 intrinsics. For example, the datatype then becomes

```C++
template<>
struct CPUSIMDComplex<float,8> {
    explicit CPUSIMDComplex<float,8>() {}
    
    union {
        Kokkos::complex<float> _data[8];
        __m512 _vdata;
    };
    ...
};
```

and the vectorized multiplication of two complex numbers

