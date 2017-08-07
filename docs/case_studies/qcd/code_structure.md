# Code Structure
Our testcode is written in C++ and designed completely from scratch. We use type definitions, templates, template-specialization, overloading and other C++ features to provide flexibility in changing precision, testing datatypes which help vectorization and also making it easier to hide architecture dependent code. The general idea is to decompose the problem into a loop over lattice site and then for each lattice site we:

* stream-in the relevant spinors (or block of spinors in case of multiple right hand sides) from memory
* project 4-spinors to 2-spinors
* read relevant gauge links and apply the dslash to those vectors
* inject 2-spinors into 4-spinors
* stream-out the solution vectors to memory

In multi-node implementations the application step would be separated into bulk- and boundary application and the former interleaved with boundary communication.
For facilitating this workflow, we define spinor and gauge link classes such as:

```C++
template<typename ST,int nspin> 
class CBSpinor {
public: 
    ...
private:
    // dims are: site, color, spin
    spin_container<ST[site,color,spin]> data;
};

template<typename GT> 
class CBGaugeField {
public:
    ...
private:
    // dims are: site, direction, color, color
    gauge_container<GT[site,4,3,3]> data;
};
```

here, ST and GT refer to spinor-type and gauge-type respectively. Those types could be SIMD or scalar types and they do not neccesarily need to be the same. The data containers can be plain arrays, e.g. for (unportable) plain implementations, or arrays decorated with pragmas (e.g. for OpenMP 4.5 offloading) or more general data container classes such as Kokkos::Views, etc.. The member functions are adopted to the container classes used in the individual implementations. Note that this design allows us to test different performance portable frameworks/methods without having to restructure large parts of the code.