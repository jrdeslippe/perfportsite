# Overview and Definition

## Overview

As shown on the detailed [facility comparison page](http://performanceportability.org/facilities/comparison/), the Cori, Theta and Titan systems have a lot 
in common including interconnect (Cray Gemini or Cray Aries) and software environment. The most striking difference between the systems from a portability 
point 
of view is the node-level architecture. 
Cori and Theta both containing Intel Knights Landing (KNL) powered nodes while Titan sports a heterogeneous architecture with an AMD 16-Core CPU 
coupled with an NVIDIA K20X GPU (where the majority of the compute capacity lies) on each node. We compare just the important node memory hierarchy and 
parallelism features in the following table:

| Node | DDR Memory | Device Memory | Cores/SMs (DP) | Vector-Width/Warp-Size (DP) | 
|------|------------|---------------|-------|--------------|
| Cori (KNL)  | 96 GB | 16 GB | 68 | 8 | 
| Theta (KNL)  | 192 GB | 16 GB | 64 | 8 |
| Titan (K20X) | | 6 GB | 14 SMs, 896 CUDA cores | 32 |

where DP stands for Double Precision and SM stands for Streaming Multiprocessor. 

Two challenges that need to be overcome by viable performance portability approaches are:

1. How to express parallelism in a portable way across both the KNL processor cores and vector-lanes and across the 896 SIMT threads that the K20x 
CUDA cores support. 

2. How to express data movement and data locality across the memory hierarchy containing both host and device memory in portable way. 

In the following pages we discuss how to measure a successful performance portable implementation, what are the available approaches and some case-studies 
from 
the Office of Science workload. First however, we turn our attention to defining what performance-portability means. 

## Definition

The 2016 DOE Center of Excellence (COE) meeting in Phoenix brought together engineers from the DOE's Office of Science and National Nuclear Security Agency 
as well as vendor staff (from Intel, NVIDIA, IBM, Cray and others) to share portability lessons and best practicies from their respective app-readiness 
programs. One of the high-level take-away messages from the meeting is that "there is not yet a universally accepted definition of 'performance 
portability'". 
There is generally agreement on what performance-portability "basically means" but the exact details differ in everyone's idea for the term. A number of 
attendees 
gave the following definitions:

* "For the purposes of this meeting, it is the ability to run an application with acceptable performance across KNL and GPU-based systems with a single 
version of source code." (Rob Neely)

* "An application is performance portable if it achieves a consistent level of performance (e.g. defined by execution time or	
other figure of merit (not percentage of peak flops across platforms)) relative to the best known implementation on each platform." (John Pennycook, Intel)

* "Hard portability = no code changes and no tuning. Software portability = simple code mods with no algorithmic changes. Non-portable = algorithmic changes" (Adrian Pope, Vitali Morozov)

* (Performance portability means) the same source code	will run productively on a variety of different	architectures" (Larkin)

* "Code is performance portable when the application team says its performance	portable!" (Richards)

For our purposes, we combine a few the ideas above into the following working definition:

<br>
**An application is performance portable if it achieves a consistent ratio of the actual time to solution to either the best-known or the theoretical best time to 
solution on each platform with minimal platform specific code required.**
<br><br>

We discuss the details on how to begin to quantify the level to which a code meets this definition on the 
[Measurement Techniques](/perfport/measurements/index.md) page.
