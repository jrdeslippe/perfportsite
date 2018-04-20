# Strategy

## Code Structure and Practices

Before diving into a performance portability strategy, there are many things an application can do to make their code more 
portabile and ultimately more productive by applying recommended software engineering practices. These include:

* Developing in a well-defined version-controlled environment
* Documenting code so other developers can quickly join and contribute to a project
* Maintaining a rigorours test-suite and automated regression test framework on multiple platforms
* Developing code in a modular way that abstracts performance-critical regions

The [Better Scientific Software (BSSw)](https://bssw.io/) site is a valuable resource---a hub for sharing information and educating about best practices.

## Developing a Performance Portability Strategy 

We noted in the introduction that the KNL and NVIDIA GPU architectures had a lot in common, including wide "vectors" or "warps," as well as multiple tiers of memory, including on-package memory. However, before diving into to any particular performance-portability programming model, it is important to develop a high-level strategy for how a given problem best maps to these similar architecture features. In exploring various approaches to performance portability, we have found that different strategies can exist for exploiting these similarities. 

## Threads and Vectors

One of the main challenges in providing a performance portability layer between KNL and GPU architectures is that vector parallelism on GPUs is expressed as 
SIMT (Single Instruction Multiple Threads) whereas a CPU contains both SMT (Simultaneous Multi-Threading) across cores/threads and SIMD (Single Instruction 
Multiple Data) across the lanes of the VPU (Vector Processing Unit). One of the challenges to be grappled with in using a performance portable approach 
is that SIMT parallelism lies somewhere in between SMT and SIMD parallelism in terms of expressibility, flexibility, and performance limitations:

* *SMT*: Each SMT thread can perform independent instructions on independent data in independent registers. The work for each thread may be expressed in a 
scalar way.

* *SIMD*: Each SIMD "vector lane" performs the same instruction on data from a single register. Vector lanes may be masked out to support branching, and 
gather/scatter instructions are supported to bring non-contiguous data in memory into a vector register. However, these often come with significant performance 
costs.

* *SIMT*: SIMT shares some qualities of SMT in the sense that each thread (running on what is referred to as a "core" on a GPU) has its own registers, and 
work for each thread can be expressed in a "scalar" way. However, like SIMD and unlike SMT, the threads are not completely 
independent. On current GPU architectures, (e.g. the K20X found in Titan) typically 32 threads form a warp in which the same instruction is being executed each cycle. Thus, if the work between threads diverges 
significantly, there is a significant reduction in performance. In addition, optimal performance is typically achieved when the threads in the warp are 
operating on contiguous data. 

How do you use these different types of parallelism in order to enable portable programming? We identify three particular strategies, each with advantages and disadvantages. It is important when beginning to develop a performance portability plan to consider which of these strategies best maps to your application.

### Strategy 1

The first strategy to performance portability is to equate SIMT threads on a GPU with SMT threads on CPU or a KNL. This has the advantage of allowing 
the programmer to fully express the SIMT parallelism, but it does lead to a couple of challenges:

1. SMT threads typically operate on independent regions of data (e.g. the programmer typically breaks an array into the biggest contiguous chunks possible 
and gives each thread a chunk to work on). On the other hand, with SIMT threads, consecutive threads in a warp are ideally given 
consecutive elements of an array to work on. This leads to the idea of coalescing - where data given to a single thread is 
strided by the warp size (typically 32). The concept of coalescing is an artifact of viewing SIMT threads like SMT threads 
instead of viewing them like vector lanes. 

2. Another level of parallelism on the KNL (the vector parallelism) is then left on the table to exploit some other way (e.g. through the compiler, possibly
with the aid of hints).

This strategy is likely most appropriate if additional vector parallelism can be easily exploited by the compiler on the KNL, if vectorization doesn't 
affect performance or if one intends to manually intervene to ensure vector parallelism is exploited on the KNL. Frameworks like Kokkos (with the concept of 
"views") can help handle the coalescing issue in a portable way. 

### Strategy 2 

The second strategy is to instead equate the SIMT threads with SIMD lanes (or a combination of SMT threads and SIMD lanes) on the KNL architecture. 
This has the benefit of allowing the programmer to fully express all parallelism available on the GPU and KNL, but also has a significant drawback: 

* Because SIMD parallelism on the CPU/KNL is typically more restrictive and less flexible to express (requiring statements like `OMP SIMD` on relatively 
straightforward loops), the programmer loses a lot of the flexibility the GPU architecture allows. 

This is generally the strategy taken by applications using OpenMP for performance portability in its current implementation. We see in the case studies that to use OpenMP to 
offload work to the GPU, one currently needs an `OMP SIMD` directive (when compiler support exists at all). 

### A Mixed Strategy

One may, in principle, define layers of parallelism to map groups of SIMT threads on a GPU (e.g., on separate SMs) to different SMTs on a CPU and leave 
additional 
parallelism available to map to CPU vector lanes. Some of the performant models have support for this type of mapping. Kokkos for example supports this concept and can then insert `OMP SIMD` 
pragmas on top of the innermost parallelizable loops when executing on a KNL or CPU. In practice, CPU performance will still ultimately depend on the 
compilers ability to generate 
efficient vector code, meaning the vector/(inner SIMT) code here is limited to relatively simple vectorizable loops compared to what the SIMT model alone 
can, in 
theory, support. For example, Kokkos ``views`` handle coalescing,
but vector parallelism on the CPU or KNL is left up to the compiler (with mixed results). As we see in the QCD case-study, the 
developers may need to intervene (and potentially add new layers of parallelism to the code, e.g. multiple right hand sides) to make sure their code 
can effectively use the wide AVX512 units on the KNL. 


## Memory Management

As we mention above, the KNL and GPU architectures both have high-bandwidth, on-device memory as well as lower bandwidth access to traditional DDR on the 
node. With support of unified virtual memory (UVM) on recent GPUs, both kinds of memory spaces can be accessed from all the components 
of GPU or KNL nodes. One difference is that 
because host memory is still separated from the GPU via PCI-express or NVLink, the gap in latency and bandwidth compared to the device memory can be 
significantly higher. 

In principle, directives like OpenMP's `map` function could be used to portably move data. The reality is that compiler implementations don't support this 
at present - mostly ignoring this when running on a CPU or KNL system (or failing to work at all on these systems). 

Kokkos allows the user to define separate host and devmem domains, which does support this functionality in a portable way, in principle, but data placement in MCDRAM on the KNL is compiler dependent which makes this a challenge to support.

In the most common node configuration at NERSC and ALCF, the KNLs are configured in cache mode where the on-chip MCDRAM is treated as a transparent last-level 
cache instead of as an addressable memory domain. In this case, applications running see only a single memory domain and explicit management of the 
MCDRAM is not required. At this time, an equivalent option doesn't exist on GPU architectures.

