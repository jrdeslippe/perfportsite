# Kokkos

[Kokkos](https://github.com/kokkos/kokkos) implements a programming model in
C++ for writing performance portable applications targeting all major HPC
platforms. For that purpose it provides abstractions for both parallel
execution of code and data management. Kokkos is designed to target complex
node architectures with N-level memory hierarchies and multiple types of
execution resources. It currently can use OpenMP, Pthreads and CUDA as backend
programming models. (_Text provided by [README](https://github.com/kokkos/kokkos/blob/master/README) in Kokkos source code repository_).

Kokkos provides two types of abstraction which insulate the application
developer from the details of expressing parallelism on a particular
architecture. One is a "memory space", which characterizes where data resides
in memory, e.g., in high-bandwidth memory, in DRAM, on GPU memory, etc. The
other type is an "execution space", which describes how execution of a kernel
is parallelized.

In terms of implementation, Kokkos expresses its memory and execution spaces
via templated C++ code. One constructs memory spaces through "Views", which are
templated multi-dimensional arrays. One then issues an execution policy on the
data. The following snippet shows matrix-vector multiplication using Kokkos
views and a "reduction" execution policy. It is taken from the Kokkos [GTC2017
tutorial
\#2](https://github.com/kokkos/kokkos-tutorials/tree/master/GTC2017/Exercises/02).

```C++
  Kokkos::View<double*>  x( "x", 128 ); // a vector of length 128
  Kokkos::View<double**> A( "A", 128, 128 ); // a matrix of size 128^2

  Kokkos::parallel_reduce( N, KOKKOS_LAMBDA ( int j, double &update ) {
    double temp2 = 0;
    for ( int i = 0; i < M; ++i ) {
      temp2 += A( j, i ) * x( i );
    }
    update += y( j ) * temp2;
  }, result );
```
