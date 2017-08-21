## Complex Numbers in Kokkos
Kokkos has its own implementation of complex numbers.
The framework supports most of the opertaions involving complex numbers but there are a few that are not yet available.
For example the power of a complex number is not defined and a few others such as multipliying, adding or subtracting a double to/from a complex number are yet to be implemented.
We can however define our own implementation and annotate the function with ```KOKKOS_INLINE_FUNCTION``` to achieve the result.

```C++
KOKKOS_INLINE_FUNCTION
Kokkos::complex<double> kokkos_square(Kokkos::complex<double> compl_num)
{
    double re = Kokkos::real(compl_num);
    double im = Kokkos::imag(compl_num);

    Kokkos::complex<double> result(re*re - im*im, 2*re*im);
    return result;
}
```

In Kokkos it is advised to use a ```Kokkos::View``` datatype inorder to store modify the data inside a Kokkos construct.
We follow the below shown technique to create a vector and matrix type of```views``` with the appropriate execution and memory spaces.

```C++
#define CUDASPACE 0
#define OPENMPSPACE 0
#define CUDAUVM 1
#define SERIAL 0
#define THREADS 0

#if OPENMPSPACE
        typedef Kokkos::OpenMP   ExecSpace;
        typedef Kokkos::OpenMP        MemSpace;
        typedef Kokkos::LayoutRight  Layout;
#endif

#if CUDASPACE
        typedef Kokkos::Cuda     ExecSpace;
        typedef Kokkos::CudaSpace     MemSpace;
        typedef Kokkos::LayoutLeft   Layout;
#endif

#if SERIAL
        typedef Kokkos::Serial   ExecSpace;
        typedef Kokkos::HostSpace     MemSpace;
#endif

#if THREADS
        typedef Kokkos::Threads  ExecSpace;
        typedef Kokkos::HostSpace     MemSpace;
#endif

#if CUDAUVM
        typedef Kokkos::Cuda     ExecSpace;
        typedef Kokkos::CudaUVMSpace  MemSpace;
        typedef Kokkos::LayoutLeft   Layout;
#endif

typedef Kokkos::RangePolicy<ExecSpace>  range_policy;

typedef Kokkos::View<Kokkos::complex<double>, Layout, MemSpace>   ViewScalarTypeComplex;
typedef Kokkos::View<Kokkos::complex<double>*, Layout, MemSpace>   ViewVectorTypeComplex;
typedef Kokkos::View<Kokkos::complex<double>**, Layout, MemSpace>  ViewMatrixTypeComplex;

};

ViewMatrixTypeComplex array1("array1", N,M);
ViewMatrixTypeComplex array2("array2", N,M);
ViewVectorTypeComplex vcoul("vcoul", ngpown)
```
As shown in the code structure section, there is a reduction being performed over a vector of complex numbers ```achtemp```
In the OpenMP version of the code we reduce these values inside individual thread-local arrays and then later accumulate the results.
But since Kokkos allows user defined reduction, we create a structure with an array of 3 complex numbers and overload the += operator for this structure.
We then perform a ```Kokkos::parallel_reduce``` on the structure.

###Kokkos+OpenMP implementation
```C++
struct achtempStruct
{
    Kokkos::complex<double> value[3];
KOKKOS_INLINE_FUNCTION
    void operator+=(achtempStruct const& other)
    {
        for (int i = 0; i < 3; ++i)
            value[i] += other.value[i];
    }
KOKKOS_INLINE_FUNCTION
    void operator+=(achtempStruct const volatile& other) volatile
    {
        for (int i = 0; i < 3; ++i)
            value[i] += other.value[i];
    }
};

Kokkos::complex<double>  achtemp[3];
achStruct achtempVar = {{achtemp[0],achtemp[1],achtemp[2]}};

Kokkos::parallel_reduce(ngpown, KOKKOS_LAMBDA (int my_igp, achtempStruct& achUpdate)
{
    for(int iw = 0; iw < 3; iw++ )
    {
        for(int ig = 0; ig < ncouls; ig++)
        {
            delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
            ...
            scht += ... * delw * array3(ig,igp)
        }
        achUpdate.value[iw] += vcoul(igp) * sch_array[iw];
    }

},achtempVar);

```
#INITIAL OBSERVATION
In this section, we will describe some of the initial hurdles faced while porting the gw-kernel using Kokkos.
Not shown in the code structure is the outermost loop of the computation (shown below), which iterates over the number of bands.
If we update the achtemp as a view inside the Kokkos construct, we loose its value when the outer loop starts the new iteration.
hence we have to store it in a separate structure in order to save its value for the next iteration.

```C++

for(int n1 = 0; n1<number_bands; ++n1)
{
    Kokkos::parallel_reduce(ngpown, KOKKOS_LAMBDA (int my_igp, achtempStruct& achUpdate)
    {
        for(int iw = 0; iw < 3; iw++ )
        {
            for(int ig = 0; ig < ncouls; ig++)
            {
                delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
                ...
                scht += ... * delw * array3(ig,igp)
            }
            achUpdate.value[iw] += vcoul(igp) * sch_array[iw];
        }

    },achtempVar);

    for(int iw=nstart; iw<nend; ++iw)
        achtemp[iw] += achtempVar.value[iw];
}
```
As shown in the above code snippet, we save the value of achtempVar in achtemp, else we loose it's value of  from iteration i to i+1.
