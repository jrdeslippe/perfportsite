# OpenMP

OpenMP is a specification for a set of compiler directives, library routines,
and environment variables that can be used to specify high-level parallelism in
Fortran and C/C++ programs. The OpenMP API uses the fork-join model of parallel
execution. Multiple threads of execution perform tasks defined implicitly or
explicitly by OpenMP directives. (_Text taken from [OpenMP
FAQ](http://www.openmp.org/about/openmp-faq/) and [API
specification](http://www.openmp.org/wp-content/uploads/openmp-4.5.pdf)._)

Although the directives in early versions of the OpenMP specification focused
on thread-level parallelism, more recent versions (especially 4.0 and 4.5) have
generalized the specification to address more complex types (and multiple
types) of parallelism, reflecting the increasing degree of on-node parallelism
in HPC architectures. In particular, OpenMP 4.0 introduced the `simd` and
`target` constructs. We discuss each of these in detail below.

## `omp simd`

Decorating a loop with the `simd` construct informs the compiler that the loop
iterations are independent and can be executed with SIMD instructions (e.g.,
AVX-512 on Intel Xeon Phi), e.g.,

```Fortran
!$omp simd
do i = 1, array_size
  a(i) = b(i) * c(i)
end do
!$omp end simd
```

Example output from a compiler optimization report for this loop is as follows:
```
LOOP BEGIN at main.f90(9,3)
   remark #15388: vectorization support: reference A(i) has aligned access   [ main.f90(10,5) ]
   remark #15388: vectorization support: reference B(i) has aligned access   [ main.f90(10,12) ]
   remark #15388: vectorization support: reference C(i) has aligned access   [ main.f90(10,19) ]
   remark #15305: vectorization support: vector length 16
   remark #15399: vectorization support: unroll factor set to 4
   remark #15301: OpenMP SIMD LOOP WAS VECTORIZED
   remark #15448: unmasked aligned unit stride loads: 2
   remark #15449: unmasked aligned unit stride stores: 1
   remark #15475: --- begin vector cost summary ---
   remark #15476: scalar cost: 6
   remark #15477: vector cost: 0.310
   remark #15478: estimated potential speedup: 19.200
   remark #15488: --- end vector cost summary ---
LOOP END
```

The `simd` construct can be combined with the traditional `parallel for` (or
`parallel do` in Fortran) constructs in order to execute the loop with both
multi-threading and with SIMD instructions, e.g.,

```Fortran
!$omp parallel do simd
do i = 1, array_size
  a(i) = b(i) * c(i)
end do
!$omp end parallel do simd
```

The optimization report for the above snippet is as follows:

```
Begin optimization report for: MAIN

    Report from: OpenMP optimizations [openmp]

main.f90(8:9-8:9):OMP:MAIN__:  OpenMP DEFINED LOOP WAS PARALLELIZED

    Report from: Vector optimizations [vec]

LOOP BEGIN at main.f90(8,9)
   remark #15388: vectorization support: reference a(i) has aligned access   [ main.f90(10,5) ]
   remark #15389: vectorization support: reference b(i) has unaligned access   [ main.f90(10,12) ]
   remark #15389: vectorization support: reference c(i) has unaligned access   [ main.f90(10,19) ]
   remark #15381: vectorization support: unaligned access used inside loop body
   remark #15305: vectorization support: vector length 32
   remark #15399: vectorization support: unroll factor set to 2
   remark #15309: vectorization support: normalized vectorization overhead 0.667
   remark #15301: OpenMP SIMD LOOP WAS VECTORIZED
   remark #15449: unmasked aligned unit stride stores: 1
   remark #15450: unmasked unaligned unit stride loads: 2
   remark #15475: --- begin vector cost summary ---
   remark #15476: scalar cost: 6
   remark #15477: vector cost: 0.370
   remark #15478: estimated potential speedup: 15.670
   remark #15488: --- end vector cost summary ---
LOOP END
```

It is important to note that compilers generally analyze loops (even those
undecorated with `omp simd`) to determine if they can be executed with SIMD
instructions; applying this OpenMP construct usually allows the compiler to
skip its loop dependency checks and immediately generate a SIMD version of the
loop. Consequently, improper use of `omp simd`, e.g., on a loop which indeed
carries dependencies between iterations, can generate wrong code. This
construct shifts the burden of correctness from the compiler to the user.

For example, consider the following loop, with a write-after-read dependency:
```Fortran
do i = 1, array_size
  a(i) = b(i) * a(i-1)
end do
```

Attempting to compile it without the `simd` construct yields the following
optimization report:

```
LOOP BEGIN at main.f90(8,3)
   remark #15344: loop was not vectorized: vector dependence prevents vectorization
   remark #15346: vector dependence: assumed FLOW dependence between a(i) (9:5) and a(i-1) (9:5)
LOOP END
```

The compiler has determined that the loop iterations cannot be executed in
SIMD. However, if we introduce the `simd` construct, this assures the compiler
(incorrectly) that the loop iterations can be executed in SIMD. Using the
construct results in the following report:

```
LOOP BEGIN at main.f90(9,3)
   remark #15388: vectorization support: reference A(i) has aligned access   [ main.f90(10,5) ]
   remark #15388: vectorization support: reference B(i) has aligned access   [ main.f90(10,12) ]
   remark #15389: vectorization support: reference A(i-1) has unaligned access   [ main.f90(10,19) ]
   remark #15381: vectorization support: unaligned access used inside loop body
   remark #15305: vectorization support: vector length 32
   remark #15399: vectorization support: unroll factor set to 2
   remark #15301: OpenMP SIMD LOOP WAS VECTORIZED
   remark #15448: unmasked aligned unit stride loads: 1
   remark #15449: unmasked aligned unit stride stores: 1
   remark #15450: unmasked unaligned unit stride loads: 1
   remark #15475: --- begin vector cost summary ---
   remark #15476: scalar cost: 6
   remark #15477: vector cost: 0.340
   remark #15478: estimated potential speedup: 17.450
   remark #15488: --- end vector cost summary ---
LOOP END
```

This example illustrates the prescriptive nature of OpenMP directives; they
allow the user to instruct the compiler precisely how on-node parallelism
should be expressed, even if the compiler's own correctness-checking heuristics
indicate that the desired approach will generate incorrect results.


## omp target

The OpenMP `target` device construct maps variables to a device data
environment and executes the construct on that device. A region enclosed with
the `target` construct is assigned a target task to be executed on the device.
This construct supports several additional keywords which provide the user with
control of which data is moved to and from the device. Specifically, data
movement is achieved via the `map` keyword, which accepts a list of variables
to be copied between the host and device.

Consider the following snippet:
```Fortran
!$omp target map(to:b,c) map(from:a)
do i = 1, array_size
  a(i) = b(i) * c(i)
end do
!$omp end target
```

The compiler report from the following code offloaded to an Intel Xeon Phi
coprocessor is as follows:

```
    Report from: Offload optimizations [offload]

OFFLOAD:main(8,9):  Offload to target MIC 1
 Evaluate length/align/alloc_if/free_if/alloc/into expressions
   Modifier expression assigned to __offload_free_if.19
   Modifier expression assigned to __offload_alloc_if.20
   Modifier expression assigned to __offload_free_if.21
   Modifier expression assigned to __offload_alloc_if.22
   Modifier expression assigned to __offload_free_if.23
   Modifier expression assigned to __offload_alloc_if.24
 Data sent from host to target
       i, scalar size 4 bytes
       __offload_stack_ptr_main_$C_V$5.0, pointer to array reference expression with base
       __offload_stack_ptr_main_$B_V$6.0, pointer to array reference expression with base
 Data received by host from target
       __offload_stack_ptr_MAIN__.34, pointer to array reference expression with base 

LOOP BEGIN at main.f90(12,3)
   remark #15388: vectorization support: reference A(i) has aligned access   [ main.f90(13,5) ]
   remark #15389: vectorization support: reference B(i) has unaligned access   [ main.f90(13,12) ]
   remark #15389: vectorization support: reference C(i) has unaligned access   [ main.f90(13,19) ]
   remark #15381: vectorization support: unaligned access used inside loop body
   remark #15305: vectorization support: vector length 32
   remark #15399: vectorization support: unroll factor set to 2
   remark #15309: vectorization support: normalized vectorization overhead 0.654
   remark #15300: LOOP WAS VECTORIZED
   remark #15449: unmasked aligned unit stride stores: 1
   remark #15450: unmasked unaligned unit stride loads: 2
   remark #15475: --- begin vector cost summary ---
   remark #15476: scalar cost: 7
   remark #15477: vector cost: 0.400
   remark #15478: estimated potential speedup: 17.180
   remark #15488: --- end vector cost summary ---
   remark #25015: Estimate of max trip count of loop=1024
LOOP END
```

The same code offloaded to an NVIDIA Tesla GPU shows the following compiler
report (from a different compiler than the ones shown above):

```
    1.           program main
    2.             implicit none
    3.
    4.             integer, parameter :: array_size = 65536
    5.             real, dimension(array_size) :: a, b, c
    6.             integer :: i
    7.
    8.    fA--<>   b(:) = 1.0
    9.    f---<>   c(:) = 2.0
   10.
   11.  + G----<   !$omp target map(to:b,c) map(from:a)
   12.    G g--<   do i = 1, array_size
   13.    G g        a(i) = b(i) * c(i)
   14.    G g-->   end do
   15.    G---->   !$omp end target
   16.
   17.             print *, a(1)
   18.
   19.           end program main

ftn-6230 ftn: VECTOR MAIN, File = main.f90, Line = 8
  A loop starting at line 8 was replaced with multiple library calls.

ftn-6004 ftn: SCALAR MAIN, File = main.f90, Line = 9
  A loop starting at line 9 was fused with the loop starting at line 8.

ftn-6405 ftn: ACCEL MAIN, File = main.f90, Line = 11
  A region starting at line 11 and ending at line 15 was placed on the accelerator.

ftn-6418 ftn: ACCEL MAIN, File = main.f90, Line = 11
  If not already present: allocate memory and copy whole array "c" to accelerator, free at line 15 (acc_copyin).

ftn-6418 ftn: ACCEL MAIN, File = main.f90, Line = 11
  If not already present: allocate memory and copy whole array "b" to accelerator, free at line 15 (acc_copyin).

ftn-6420 ftn: ACCEL MAIN, File = main.f90, Line = 11
  If not already present: allocate memory for whole array "a" on accelerator, copy back at line 15 (acc_copyout).

ftn-6430 ftn: ACCEL MAIN, File = main.f90, Line = 12
  A loop starting at line 12 was partitioned across the 128 threads within a threadblock.
```

Note in the last compiler report that OpenMP automatically threads the loop and
partitions the threads into threadblocks of the appropriate size for the device
executing the loop.

## Benefits and Challenges

### Benefits

* Available for many different languages
* Prescriptive control of execution
* Allow performance optimization
* Controlled by well-defined standards bodies

### Challenges

* Sensitive to compiler support/maturity
* Evolving standards

## Summary

The following table summarizes the OpenMP compiler support.

| Compiler | Language Support | Architecture Support | Notes |
|----------|------------------|----------------------|-------|
|    GNU   | C/C++ (>6.1), Fortran (>7.2) | Range of CPUs, nvidia GPUs   | performance problems on CPU ([bug #80859](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=80859)), compilation problems with ```enter data``` and ```exit data``` constructs ([bug #81896](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=81896)) |
| Intel    | C/C++, Fortran (>17.0)   | x86-64 CPUs | generated code in target region can be wrong, working on a testcase to demonstrate that problem |
| Cray     | C/C++, Fortran (>8.5)    | x86-64 CPUs, nvidia GPUs    | failure at link time when host-offloading is used (bug #189760) |
| IBM    | C/C++ (>13.1.5), Fortran (>15.1.5) | Power CPUs, nvidia GPUs | multiple-definitions link error when ```target``` region is contained in header file which is included by multiple compilation units (bug #147007) |