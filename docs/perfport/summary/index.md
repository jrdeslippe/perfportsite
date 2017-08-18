# Summary and Recommendations

We summarize below some of our high-level findings from the survey of available performance-portability options, the case-studies from the Office of Science 
workload and from the outcome of recent DOE performance portability workshops.

## Comparison of Leading Approaches

|Approach|Benefits|Challenges|
|:------------:|:-------------------:|:------------:|
|Libraries  | Highly portable, not dependent on compiler implementations | Many libraries (e.g. CUFFT) are C only (requiring explicit interafces to use in FORTRAN) and don't have common interfaces. In many cases libraries don't exist for problem |
|OpenMP 4.5 | Standardized. Support for C, C++, FORTRAN and others. Simple to get started. | Limited expressibility (particularly on GPUs). Reliant on quality of compiler implementation - which are generally immature on both GPU and CPU systems. |
|OpenACC    | Standardized. Support for C, C++, FORTRAN. | Limited support in compilers, especially free compilers (e.g. GNU)  |
|Kokkos     | Allows significant expressibility (particularly on GPUs.) | Only supports C++. Vector parallelism. |
|DSLs       | Highest expressibility for appropriate problems | Limited to only a small number of communities. Need to be maintained and supported for new architectures |

## State of Available Approaches

We noted in the introduction that the KNL and NVIDIA GPU architectures had a lot in common, including wide "vectors" or "warps," as well as multiple tiers of 
memory, including on-package memory. In exploring various approaches, we have found that different models have a different philosophy in exploiting these 
similarities. 

### Threads and Vectors

One of the main challenges in providing a performance portability layer between KNL and GPU architectures is that vector parallelism on GPUs is expresed as 
SIMT (Single Instruction Multiple Threads) whereas a CPU contains both SMT (Simultaneous Multi-Threading) across cores/threads and SIMD (Single Instruction 
Multiple Data) across the lanes of the VPU (Vector Processing Unit). One of the challenges to be grappled with in using a performance portable approach 
is that SIMT parallelism lies somewhere in between SMT and SIMD parallelism in terms of expressibility, flexibility, and performance limitations:

* *SMT*: Each SMT thread can perform independent instructions on independent data in independent registers. The work for each thread may be expressed in a 
scalar way.

* *SIMD*: Each SIMD "vector lane" performs the same instruction on data from a single register. Vector lanes may be masked out to support branching, and 
gather/scatter instructions are supported to bring non-contiguous data in memory into a vector register. However, these often come with significant performance 
costs.

* *SIMT*: SIMT shares some qualities of SMT in the sense that each thread (running on what is referred to as a "core" on a GPU) has its own registers, and 
work for each thread can expressed in a "scalar" way. However, like SIMD and unlike SMT, the threads are not completely 
independent. On current GPU architectures, (e.g. the K20X found in Titan) typically 32 threads form a warp in which the same instruction is being executed each cycle. Thus, if the work between threads diverges 
significantly, there is a signficant reduction in performance. In addition, optimal performance is typically achieved when the threads in the warp are 
operating on contiguous data. 

How do you use these different types of parallelism these in order to enable portable programming? We identify three particular approaches, each with advantages and disadvantages. 

#### Approach 1

The first approach to performance portability is to equate all SIMT threads on a GPU with SMT threads on CPU or a KNL. This has the advantage of allowing 
the programmer to fully express the SIMT parallelism, but it does lead to a couple of challenges:

1. SMT threads typically operate on independent regions of data (e.g. the programmer typically breaks an array into the biggest contiguous chunks possible 
and give each thread a chunk to work on). On the other hand, with SIMT threads, consecutive threads in a warp are ideally given 
consecutive elements of an array to work on. This leads to the idea of coalescing - where data given to a single thread is 
strided by the warp size (typically 32). The concept of coalescing is an artifact of viewing SIMT threads like SMT threads 
instead of viewing them like vector lanes. 

2. Another level of parallelism on the KNL (the vector parallelism) is then left on the table to exploit some other way (e.g. through the compiler, possibly
with the aid of hints).

This approach is generally taken in most applications using Kokkos for performance portability. Kokkos ``views`` handle coalescing,
but vector parallelism on the CPU or KNL is often left up to the compiler (often, with mixed results). As we see in the QCD case-study, the 
developers may need to intervene (and potentially add new layers of parallelism to the code, e.g. multiple right hand sides) to make sure their code 
can effetively use the wide AVX512 units on the KNL. 

#### Approach 2 

The second approach is to instead equate the SIMT threads and SIMD lanes (or a combination of SMT threads and SIMD lanes) on the KNL architecture. 
This has the benefit of allowing the programmer to fully express all parallelism available on the GPU and KNL, but also has a signficant drawback: 

* Because SIMD parallelism on the CPU/KNL is typically more restrictive and less flexible to express (requiring statements like `OMP SIMD` on relatively 
straightfoward loops), the programmer loses a lot of the flexibility the GPU architecture allows. 

This is generally the approach taken by OpenMP for performance portability in the current implementation. We see in the case studies that to use OpenMP to 
offload work to the GPU, one needs an `OMP SIMD` directive (when it is supported by the compiler at all). 

#### A mixed approach?

One may, in principle, use the concepts of "teams" to map groups of SIMT threads on a GPU (e.g., on separate SMs) to different SMTs on a CPU and leave 
additional 
parallelism available to map to CPU vector lanes. Kokkos has support for this type of mapping. Kokkos can then insert `OMP SIMD` 
pragmas on top of the innermost parallelizable loops when executing on a KNL or CPU. In practice, CPU performance will still ultimately depend on the 
compilers ability to generate 
efficient vector code, meaning the parallel code here is limited to relatively simple vectorizable loops compared to what SIMT can, in theory, support.

### Memory Management

As we mention above, the KNL and GPU architectures both have high-bandwidth, on-device memory as well as lower bandwidth access to traditional DDR on the 
node. With support of unified virtual memory (UVM) on recent GPUs, both kinds of memory spaces can be accessed from all the components 
of GPU or KNL nodes. One difference is that 
because host memory is still separated from the GPU via PCI-express or NVLink, the gap in latency and bandwidth compared to the device memory can be 
signficantly higher. 

In principle, directives like OpenMP's `map` function could be used to portably move data. The reality is that compiler implementations don't support this 
at present - mostly ignoring this when running on a CPU or KNL system (when they work at all on these systems). 

Kokkos allows the user to define separate host and devmem domains, which does support this functionality in a portable way.

In many cases (the most common configuration at NERSC and ALCF), the KNLs are configured in cache mode where the on-chip MCDRAM is treated as a last-level 
cache instead of as a addressable memory domain. In this case, applications running see only a single domain. In this case, explicity management of the 
MCDRAM is not required. At this time, an equivalent option doesn't exist on GPU architectures.

## Recommendations

At present, the reality is that the options for writing performance portable code are limited in scope and are evolving 
rapidly (see individual approach pages for lists of pros and cons). Therefore, as we see in our case studies, it is likely some 
level of code divergence (`IFDEF`s etc) will be necessary to get code 
that performs near its ceiling on all of Cori, Theta, Titan and Summit. 

However, we've seen that performance-portable approaches and implementations are becoming more and more possible. This rate of 
improvement makes this a good time to evaluate these approaches in your application with an eye towards devising a long-term strategy. 

In general, we have the following recommendations for pursuing performance portable code:

0. Actively profile your application using our suggested tools to make sure you have identified a minimal set of performance critical regions. 

1. If a well-supported library or DSL is available to address your performance critical regions, use it.

2. If you have an existing code that is *not* written in C++, evaluate whether OpenMP 4.5 can support your application with minimal code differences.
OpenACC is another possible path, and might be approriate if you need to interoperate with a limited amount of GPU-specific code (e.g. a small amount of CUDA
that is used in a particularly performance-sensitive piece of code). However, the default level of maturity for OpenACC on the non-GPU platforms is an open question. 

3. If you have an existing code that *is* written in C++, evaluate whether Kokkos or OpenMP 4.5 can support your application with minimal code differences, 
considering the above discussion and the pros and cons for each approach. 

4. Reach out to your DOE SC facility with use cases and deficiencies in these options so that we can actively push for changes in the upcoming 
framework releases and advocate in the standards bodies.

