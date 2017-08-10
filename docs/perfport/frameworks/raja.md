# RAJA

RAJA is a collection of C++ software abstractions, being developed at
Lawrence Livermore National Laboratory (LLNL), that enable architecture
portability for HPC applications. The overarching goals of RAJA are to:

  * Make existing (production) applications *portable with minimal disruption*
  * Provide a model for new applications so that they are portable from
    inception.

_(Text taken from RAJA [README](https://github.com/LLNL/RAJA/blob/develop/README.md).)_

The main conceptual abstraction in RAJA is a loop. A typical large multiphysics
code may contain O(10K) loops and these are where most computational work is
performed and where most fine-grained parallelism is available. RAJA defines a
systematic loop encapsulation paradigm that helps insulate application
developers from implementation details associated with software and hardware
platform choices. Such details include: non-portable compiler and
platform-specific directives, parallel programming model usage and constraints,
and hardware-specific data management. _(Text taken from [RAJA
Primer](https://software.llnl.gov/RAJA/primer.html).)_

RAJA implements three primary encapsulations: _execution policies_,
_IndexSets_, and _data type encapsulation_. The execution policy instructs the
compiler regarding how the loop should execute and/or parallelized. IndexSets
describe how the loop iteration space is traversed, e.g., stride-1, stride-2,
tiled, etc. Data type encapsulation describes where and how the data is located
in memory, e.g., its alignment on cache line boundaries, and aliasing
properties.

An example loop which adds two vectors, ported to RAJA and parallelized with
OpenMP, is shown below (taken from the [RAJA
examples](https://github.com/LLNL/RAJA/tree/feature/artv3/intro-examples/examples)):

```C++
/*
  RAJA::omp_parallel_for_exec - executes the forall loop using the
  #pragma omp parallel for directive
*/
RAJA::forall<RAJA::omp_parallel_for_exec>
  (RAJA::RangeSegment(0, N), [=](RAJA::Index_type i) {
    C[i] = A[i] + B[i];
  });
```

where `RangeSegment(0, N)` generates a sequential list of numbers from 0 to
`N`. The same loop parallelized and executed on a GPU with CUDA looks similar:

```C++
RAJA::forall<RAJA::cuda_exec<CUDA_BLOCK_SIZE>>
  (RAJA::RangeSegment(0, N), [=] __device__(RAJA::Index_type i) {
    C[i] = A[i] + B[i];
  });
checkSolution(C, N);
```
