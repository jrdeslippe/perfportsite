# Summary and Recommendations

## Comparison of Approaches

|Approach|Benefits|Challenges|
|:------------:|:-------------------:|:------------:|
|OpenMP 4.5 | Standardized. Support for C, C++, Fortran | Reliant on quality of compiler implementation (which vary a lot) |
|Kokkos     | Allows significant expressability (particularly on GPUs.) | Only supports C++. Vector parallelism. N |
|RAJA|      |    |

## State of the Field

We noted in the introduction that the KNL and NVIDIA GPU architectures had a lot in common, including wide "vectors" or "warps" as well as multiple tiers of 
memory, including on-package memory. In exploring varous approaches, we have found that different models have a different philosophy in explointing these 
similarities. 

### Threads and Vectors

One of the main challenges in providing a performance portability layer between KNL and GPU architectures is that vector parallelism on GPUs is expresed as 
SIMT (Single Instruction Multiple Threads) whereas a CPU contains both SMT (Simultaneous Multi-Threading) across cores/threads and SIMD (Single Instruction 
Multiple Data) across the lanes of the VPU (Vector Processing Unit). One of the challenges you need to grapple with in using a performance portable approach 
is that SIMT parallelism lies somewhere in between SMT and SIMD parallelism in terms of expressability and performance limitations:

* *SMT*: Each thread can perform independent instructions on independent data in independent registers. The work for each threads work is expressed in a 
scalar way.

* *SIMD*: Each "vector lane" performs the same instruction on data from single register. Vector lanes may be masked out to support branching and 
gather/scatter instructions are supported to bring non-contiguous data in memory into a vector register. However, these come with significant performance 
costs.

* *SIMT*: This shares some qualities of SMT in the sense that each thread (running on what is referred to a "core" on a GPU) has its own registers and work 
can expressed in a scalar way, that can in principle, diverge between threads. However, like SIMD and unlike SMT, the threads are not completely 
independent. Typically 32 threads form a warp in which the same instruction is being executed each cycle. Thus, if the work between threads diverges 
significantly, there is a signficant reduction in performance. In addition, optimal performance is typically achieved when the threads in the wap are 
operating on contiguous data. 

So how do you equate these? There are a couple approaches, that both have advantages and disadvantages. 

#### Approach 1

The first approach to performance portability is to equate all SIMT threads on a GPU with SMT threads on CPU or a KNL. This has the advantage of allowing 
the programming to fully express the SIMT parallelism, but it leads to a couple challenges:

1. SMT threads typically want to work on independent regions of data (e.g. you'd typically want break an array into the biggest contiguous chunks you can 
and give each thread a chunk to work on. While with SIMT threads, you'd want to give consecutive threads in a warp consecutive elements of an array to work 
with - leading to the idea of coalescing where data given to single thread is strided by the warp size (typically 32). The concept of coalescing is an 
artifact of viewing SIMT threads like SMT threads instead of viewing them like vector lanes. 

2. Another level of parallelism on the CPU or KNL (the vector parallelism) is then left on the table to exploit some other way.

This approach is generally taken in most applications using Kokkos for performance portability. Kokkos views generally handle the coalescing issue for 
the program, but vector parallelism on the CPU or KNL is usually left up to the compiler to handle with mixed results. As we see in the QCD case-study, the 
developers may need to intervene (and potentially add new layers of parallelism to the code, like multiple right hand sides) to make sure their code 
can effetively uses the wide AVX512 units. 

#### Approach 2 

The second approach is to equate instead the SIMT threads and SIMD lanes (or combination of SMT threads and SIMD lanes) on the CPU or KNL architecture. This 
has the benefit of allowing the programmer to fully express all parallelism available on the GPU and KNL, but also has a signficant drawback: 

* Because SIMD parallelism on the CPU/KNL is typically more restrictive and less flexible to express (requiring statements like `OMP SIMD` on relatively 
straightfoward loops), the programmer loses a lot of the flexibility the GPU architecture allows. 

This is generally the approach taken by OpenMP for performance portability in the current implementation. We see in the case studies, that to use OpenMP to 
offload work to the GPU, one needs an `OMP SIMD` directive (when it is supported by the compiler at all). 

#### A mixed approach?

One may in principle, use the concepts of "teams" to map groups of SIMT threads (separate SMs for example) to different SMTs on a CPU and leave additional 
parallelism to map to CPU vector lanes. Kokkos has support for this type of mapping, in principle. Kokkos can then insert `OMP SIMD` 
pragmas on top of the innermost parallelizable loops. In practice, your CPU performance will still ultimately depend on the compilers ability to generate 
efficient vector code, meaning the parallel code here is limited to relatively simple vectorizable code compared to what SIMT can, in principle, support.

### Memory Management

As we mention above, the KNL and GPU

## Recommendations

At this point in time, the reality is that the options for writing performance portable code are fairly immature and evolving rapidly. But, as we saw in our 
case studies, likely some level of code divergence (`IFDEFS` etc) will be necessary to get code that performs near its ceiling on all of Cori, Theta, Titan 
and Summit. 
