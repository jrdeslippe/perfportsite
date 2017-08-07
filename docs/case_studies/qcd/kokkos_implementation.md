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
## Some Caveats

