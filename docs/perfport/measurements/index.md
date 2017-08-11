# Measuring Performance Portability

As discussed in the previous section, performance portability can be an elusive topic to quantify 
and different engineers often provide different definitions or measurement techniques.

## Measuring Portability

Measuring 'portability' itself is somewhat more well defined. One can, in principle, measure the 
total lines of code used in common across different architectures vs. the amount of code intended 
for a single architecture via ``IFDEF`` pre-processing statements, separate routines and the like. A code with 0% 
architecture specfic code being completely portable and a code with a 100% architecture specific 
code being essentially made up of multiple applications for each architecture. 

One subtlety that this approach hides is that it is possible that shared source-code requires more lines than source-code intended for a single architecture 
or, in some cases, even two sets of separate source-code intended for multiple architectures. We ignore this case for now, assuming that using a portable 
approach to express an algorithm doesn't signficant change the amount of code required. 

## Measuring Performance

'Performance', even on a single architecture, is a bit less simple to define and measure. In 
practice, scientists generally care about the quality and quantity of scientific output they 
produce. This typically maps for them to relative performance concepts, such as how much faster 
can a particular run or set of runs run today than yesterday or on this machine than that. The 
drawback of trying to measure performance in this way is that the baseline is arbitrary - i.e. you 
don't know how well your code is performing on any architecture compared to how it 'should' be 
performing if it were well optimized.

One may in principle define absolute performance as a measure of the actual floating point operations (or, for example, integer operations) per second 
(FLOPS) of an 
application during execution compared to the theoretical peak performance of the system or fraction of the system in use, as say reported on the Top 500 
list - [Top500.org](https://www.top500.org) - or as reported in the system specs on NERSC, ALCF and OLCF websites.

However, this is a poor measure of application performance (and a particularly poor measure to use when trying to quantify performance portability) for a 
number of reasons:

* The application or algorithm may be fundamentally limited by an aspect of the HPC system other than the compute capability (number of cores/theads, 
clock-speed and vector/instruction-sets)

* The application or algorithm may be fundamentally limited by *different* aspects of the system on different HPC system. 

As an example, an implemenation of an algorithm that is limited by memory bandwidth may be achieving the best performance it theoretially can multiple 
architectures but could be achieving widely varying percentage of peaks FLOPS on the different systems. 

Instead we advocate for one of two approaches for defining performance against expected or optimal performance on the system for algorithm:

### 1. Compare against a known, well-recognized (potentially non-portable), implementation. 

Some applications, algorithms or methods have well-recognized optimal (often hand-tuned) implementations on different architectures. These can be used as a 
baseline for defining relative performance of portable versions. Our Chroma application case-study shows this approach. [See 
here](/case_studies/qcd/overview.md) 

Many performance tools exist at ALCF, NERSC and OLCF for the purposes profiling applications, regions of applications and determining performance limiters 
when comparing different implementation of an algorithm or method. See the comprehensive list [here](/facilities/tools.md) with links to detailed 
instructions and example use-cases at each site. 

### 2. Use the roofline approach to compare actual to expected performance

As discussed above, the major limitation of defining performance relative to the peak FLOPS capability of the system is that applications in practice are 
limited by many different aspects of an HPC system. 

The roofline performance model and extensions to the roofline model attempt to take these into account. In the roofline approach, one defines various 
theoretial performance ceilings for an algorithm or implementation with various properties. In the simplest model, one may classify an algorithm based on 
its DRAM arithmetic-intensity - that is the ratio of the FLOPs performed vs the data moved from main-memory (DRAM) to the processor over the course of 
execution, which can be measured for a given application as described on the subpages. Below, we show the performance ceilings provided by the roofline 
model on KNL for applications as a function of the DRAM arithmetic-intensity:

<center><img src="KNLRoofline.png" width=500></center>

Here the blue line represents the optimal performance on the system that can be achieved for an application running out of the KNL High-Bandwidth Memory 
(HBM) with a given
DRAM-AI (the x-axis value). For low
values of DRAM-AI, the performance is limited by the diagonal ceiling, meaning that memory-bandwidth is the limiting factor. The location of the diagonal
line are typically computed empiracally from the available bandwidth reported by stream triad. CITE stream.

For high values of DRAM-AI,
memory bandwidth no longer limits performance and one can, in principle, achieve the max compute performance on the system. However, for such cases we draw 
other ceilings that represent common limitations in algorithms or implementations of algorithms. The dashed-dotted green line labeled "-ILP" is the
performance ceiling for applications that: 1. do not provide a balance of multiply and add instructions, or simply don't use the Fused Multiply Add (FMA)
instructions on the processor and 2. don't have enough instruction level parallelism to keep both VPUs on the KNL busy. The dashed purple line labeled 
"-Vectorization" is performance ceiling of an algorithm or implementation that, in addition to the above two deficiencies, lacks vectorization (a 
combined factor of 32 reduction in the ceiling).

For applications that limited by other system properties, it is possible to extend the roofline model to include related ceilings. For example, we commonly    
extend the roofline approach to use arithmetic-intensities based on data movement from different levels of cache (e.g. L1, L2 on the KNL), in order to 
discover the relevant limiting cache level. The figure below shows an example of such a plot of an application limited by the L2 cache level.

<center><img src="MultiRoofline.png" width=500></center>

In addition, for applications with non-stream like memory access patterns, lower memory-ceilings may be computed 
from benchmark values. For example, many codes use strided or indirect-addressed (scatter/gather) patterns. In some cases memory-latency is the limiting resources. 
For example we compute the following ceilings for different access patterns empirically:

For polynomial access pattern: x[i] = (x[i]+c0)

| System                | DRAM  | L2     | L1     | GEMM   |
|-----------------------| ------|--------|-----------------|
| Titan (Kepler)        | 161   | 559    | -      | 1226   |
| Summit Dev (4 Pascal) | 1930  | 6507   | -      | 17095  |
| Cori (KNL)            | 413   | 1965   | 6443   | 2450   |

Non contiguous accesses can also lower the effective bandwidth available:

| Access Pattern  |  KNL Effective Bandwidth (Cache Mode) |
|----------|----------|---------|
| Dot Product | 219 |
| Stride 2 Dot Product | 96 | 
| Stride 100 Dot Product | 31 |
| Stride 10000 Dot Product | 20 | 

!!More numbers coming from protonu!!

Finally, one may additional define an AI value and roofline-ceiling for data coming from off-node due to internode 
communication. The relevant bandwidth here is the injection bandwidth of the node:

| System:              | Cori/Theta | Titan    | Summit  |
| Injection Bandwidth: | 8 GB/s     | 6.4 GB/s | 23 GB/s |

The value of the roofline approach is that relative performance of an application kernel to relevant ceilings (those related to fundamental limitations in an algorithm 
that cannot be overcome via optimization) allow us to define an absolute performance ratio for each architecture to quantity absolute performance and performance 
portability. 
