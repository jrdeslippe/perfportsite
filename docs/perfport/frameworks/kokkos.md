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

## Nested parallelism

Modern CPU architectures exhibit a hierarchy of parallelism, and an application
must exploit the complete hierarchy in order to achieve good performance. Each
level of the hierarchy is generally characterized by a group of execution
resources which share a pool of memory.

On manycore CPUs such as Intel Xeon Phi, each processor contains ~70 cores,
each of which supports 512 bit-wide SIMD instructions, and supports execution
of 4 simultaneous hardware threads. On GPU-accelerated architectures, the host
CPU has most of these same features, and the GPU often exhibits a very
different type of parallelism - a GPU may feature many streaming
multiprocessors, each of which executes a large number of threads, which are
grouped into clusters which execute synchronously.

Kokkos addresses this hierarchy via nested parallelism. In particular, at each
level of a loop nest one can choose which execution policy to use. For example,
on Xeon Phi, one may wish to use multi-threading for the coarsest level of
parallelism, and SIMD instructions for the finest level. On a GPU, one may wish
to use multiple streaming multiprocessors as the coarsest level, and warps of
threads as the finest level. One can achieve this with the following example
code (taken from [Exercise 6 of the GTC2017
tutorials](https://github.com/kokkos/kokkos-tutorials/tree/master/GTC2017/Exercises/06)):

```C++
for ( int repeat = 0; repeat < nrepeat; repeat++ ) {
  // Application: <y,Ax> = y^T*A*x
  double result = 0;

  Kokkos::parallel_reduce( team_policy( E, Kokkos::AUTO, 32 ), KOKKOS_LAMBDA (
  const member_type &teamMember, double &update ) {
    const int e = teamMember.league_rank();
    double tempN = 0;

    Kokkos::parallel_reduce( Kokkos::TeamThreadRange( teamMember, N ), [&] (
    const int j, double &innerUpdateN ) {
      double tempM = 0;

      Kokkos::parallel_reduce( Kokkos::ThreadVectorRange( teamMember, M ), [&]
      ( const int i, double &innerUpdateM ) {

        innerUpdateM += A( e, j, i ) * x( e, i );
      }, tempM );

      innerUpdateN += y( e, j ) * tempM;
    }, tempN );

    Kokkos::single( Kokkos::PerTeam( teamMember ), [&] () {
      update += tempN;
    });
  }, result );
```
