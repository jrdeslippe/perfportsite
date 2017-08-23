The original code C++ code structure is as follows :

```C++
for(int igp = 0; igp<ngpown; ig++)
{
    for(int iw = 0; iw < 3; iw++ )
    {
        for(int ig = 0; ig < ncouls; ig++)
        {
            delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
            ...
            scht += ... * delw * array3(ig,igp)
        }
        achtemp[iw] += sch_array[iw] * vcoul[igp];
    }
}
```
There are 3 nested loops and nearly 97% of the computation happens in the innermost loop.
The outermost loop is distributed among the threads for parallel execution and involves a reduction.
The innermost loop is vectorized.
Since OpenMP does not support reduction over complex variables, we update them inside individual threads and then accumulate the final result at the end.
The OpenMP 3.0 follows the following structure

```C++
#pragma omp parallel for shared(wxt, array1, vcoul[0:ngpown])  firstprivate(...) schedule(dynamic) private(tid)
for(int igp = 0; igp<ngpown; ig++)
{
    for(int iw = 0; iw < 3; iw++ )
    {
        for(int ig = 0; ig < ncouls; ig++)
        {
            delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
            ...
            scht += ... * delw * array3(ig,igp)
        }
        (*ach_threadArr_vla)[tid][iw] += sch_array[iw] * vcoul[igp];
    }
}
#pragma omp simd
    for(int iw=nstart; iw<nend; ++iw)
        for(int i = 0; i < numThreads; i++)
            achtemp[iw] += (*achtemp_threadArr_vla)[i][iw];

```

To port the application for an accelerator using OpenMP4.5x we use the target clause to offload the computation.
The target implementation has following structure:

```C++
#pragma omp target map(to:array2[0:ncouls], vcoul[0:ngpown]) map(from: achtemp_threadArr_vla[0:numberThreads*3])
{
    ...
#pragma omp teams distribute parallel for shared(wxt, array1, vcoul)  firstprivate(...) schedule(dynamic) private(tid)
    for(int igp = 0; igp<ngpown; ig++)
    {
        for(int iw = 0; iw < 3; iw++ )
        {
            for(int ig = 0; ig < ncouls; ig++)
            {
                delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
                ...
                scht += ... * delw * array3(ig,igp)
            }
            (*ach_threadArr_vla)[tid][iw] += scht * vcoul[igp];
        }
    }
}
#pragma omp simd
    for(int iw=nstart; iw<nend; ++iw)
        for(int i = 0; i < numThreads; i++)
            ach[iw] += (*ach_threadArr_vla)[i][iw];

```
For intel compilers we need the flag ```-qopenmp-offload=host``` and in case of GCC with for the NVIDIA GPUs we need the ```-foffload=nvptx-none``` flag during compilation.

* ```#pragma omp target ``` - offload the code block on the device
* ``` map(to:var, arr[0:N]) ``` - copy the data on to the device
* ``` map(from:var, arr[0:N]) ```- copy data from the device
* ```#pragma omp teams ``` - Create thread teams
* ``` distribute ``` - distribute the iterations of the loop over thread teams
* ```parallel for ``` - parallelize the iterations over the threads inside thread teams

The original code C++ code structure is as follows :

```C++
for(int igp = 0; igp<ngpown; ig++)
{
    for(int iw = 0; iw < 3; iw++ )
    {
        for(int ig = 0; ig < ncouls; ig++)
        {
            delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
            ...
            scht += ... * delw * array3(ig,igp)
        }
        achtemp[iw] += sch_array[iw] * vcoul[igp];
    }
}
```
There are 3 nested loops and nearly 97% of the computation happens in the innermost loop.
The outermost loop is distributed among the threads for parallel execution and involves a reduction.
The innermost loop is vectorized.
Since OpenMP does not support reduction over complex variables, we update them inside individual threads and then accumulate the final result at the end.
The OpenMP 3.0 follows the following structure

```C++
#pragma omp parallel for shared(wxt, array1, vcoul[0:ngpown])  firstprivate(...) schedule(dynamic) private(tid)
for(int igp = 0; igp<ngpown; ig++)
{
    for(int iw = 0; iw < 3; iw++ )
    {
        for(int ig = 0; ig < ncouls; ig++)
        {
            delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
            ...
            scht += ... * delw * array3(ig,igp)
        }
        (*ach_threadArr_vla)[tid][iw] += sch_array[iw] * vcoul[igp];
    }
}
#pragma omp simd
    for(int iw=nstart; iw<nend; ++iw)
        for(int i = 0; i < numThreads; i++)
            achtemp[iw] += (*achtemp_threadArr_vla)[i][iw];

```

To port the application for an accelerator using OpenMP4.5x we use the target clause to offload the computation.
The target implementation has following structure:

```C++
#pragma omp declare target
void flagOCC_solver(double , std::complex<double>* , int , int , std::complex<double>* , std::complex<double>* , std::complex<double>* , std::complex<double>& , std::complex<double>& , int , int , int , int , int );

void reduce_achstemp(int , int , int*, int , std::complex<double>* , std::complex<double>* , std::complex<double>* , std::complex<double>& ,  int* , int , double* );

void ssxt_scht_solver(double , int , int , int , std::complex<double> , std::complex<double> , std::complex<double> , std::complex<double> , std::complex<double> , std::complex<double> , std::complex<double> , std::complex<double>& , std::complex<double>& , std::complex<double> );
#pragma omp end declare target


#pragma omp target map(to:array2[0:ncouls], vcoul[0:ngpown]) map(from: achtemp_threadArr_vla[0:numberThreads*3])
{
    ...
#pragma omp teams distribute parallel for shared(wxt, array1, vcoul)  firstprivate(...) schedule(dynamic) private(tid)
    for(int igp = 0; igp<ngpown; ig++)
    {
        for(int iw = 0; iw < 3; iw++ )
        {
            for(int ig = 0; ig < ncouls; ig++)
            {
                delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
                ...
                scht += ... * delw * array3(ig,igp)
            }
            (*ach_threadArr_vla)[tid][iw] += scht * vcoul[igp];
        }
    }
}
#pragma omp simd
    for(int iw=nstart; iw<nend; ++iw)
        for(int i = 0; i < numThreads; i++)
            ach[iw] += (*ach_threadArr_vla)[i][iw];

```
Function accessed from inside the ```target``` directive need to be declared inside the ```#pragma omp declare target ``` and ```#pragma omp end declare target```.
For intel compilers we need the flag ```-qopenmp-offload=host``` and in case of GCC with for the NVIDIA GPUs we need the ```-foffload=nvptx-none``` flag during compilation.

* ```#pragma omp target ``` - offload the code block on the device
* ``` map(to:var, arr[0:N]) ``` - copy the data on to the device
* ``` map(from:var, arr[0:N]) ```- copy data from the device
* ```#pragma omp teams ``` - Create thread teams
* ``` distribute ``` - distribute the iterations of the loop over thread teams
* ```parallel for ``` - parallelize the iterations over the threads inside thread teams

