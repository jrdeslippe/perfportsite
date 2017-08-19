# Performance Analysis Tools

Evaluating application performance portability across diverse computing
architectures often requires the aid of performance analysis tools. Such tools
provide detailed information and statistics characterizing an application's
usage of the architecture, and can guide the developer as she optimizes
bottlenecks to achieve higher performance.

Each ASCR facility is equipped with a wide range of tools for measuring
application performance. The applications running at the three facilities
exhibit a broad range of demands from computer architectures - some are limited
by memory bandwidth, others by latency, and others still by the CPU itself. The
performance measurement tools available at the ASCR facilities can measure in
detail how an application uses each of these resources. They include, but are
not limited to, the list provided below. The description of each tool is copied
from its official documentation.

- [Allinea MAP](https://www.allinea.com/products/map):
  Allinea MAP is the profiler for parallel, multithreaded or single threaded C,
  C++, Fortran and F90 codes. It provides in depth analysis and bottleneck
  pinpointing to the source line.
- [Cray Performance Measurement and Analysis
  Tools](https://pubs.cray.com/content/S-2376/6.5.0/cray-performance-measurement-and-analysis-tools-user-guide-650-s-2376):
  The Cray Performance Measurement and Analysis Tools (or CrayPat) are a suite
  of utilities that enable the user to capture and analyze performance data
  generated during the execution of a program on a Cray system. The information
  collected and analysis produced by use of these tools can help the user to
  find answers to two fundamental programming questions: _How fast is my
  program running?_ and _How can I make it run faster?_
- [HPCToolkit](http://hpctoolkit.org/): HPCToolkit is an integrated suite of
  tools for measurement and analysis of program performance on computers
  ranging from multicore desktop systems to the nation's largest
  supercomputers. By using statistical sampling of timers and hardware
  performance counters, HPCToolkit collects accurate measurements of a
  program's work, resource consumption, and inefficiency and attributes them
  to the full calling context in which they occur. HPCToolkit works with
  multilingual, fully optimized applications that are statically or
  dynamically linked.
- [Intel Advisor](https://software.intel.com/en-us/intel-advisor-xe):
  Intel Advisor is used early in the process of adding vectorization into your
  code, or while converting parts of a serial program to a parallel
  (multithreaded) program. It helps you explore and locate areas in which the
  optimizations might provide significant benefit. It also helps you predict the
  costs and benefits of adding vectorization or parallelism to those parts of
  your program, allowing you to experiment.
- [Intel VTune Amplifier](https://software.intel.com/en-us/intel-vtune-amplifier-xe):
  Intel VTune Amplifier is a performance analysis tool targeted for users
  developing serial and multithreaded applications.
- [nvprof](http://docs.nvidia.com/cuda/profiler-users-guide/index.html):
  nvprof enables the collection of a timeline of CUDA-related activities on both
  CPU and GPU, including kernel execution, memory transfers, memory set and CUDA
  API calls and events or metrics for CUDA kernels.
- [Tuning and Analysis Utilities (TAU)](https://www.cs.uoregon.edu/research/tau/home.php):
  TAU Performance System is a portable profiling and tracing toolkit for
  performance analysis of parallel programs written in Fortran, C, C++, UPC,
  Java, Python.

##Using Tools on ASCR Facility Systems

Below are brief instructions and links to documentation or presentations on
using some of the performance analysis tools on the current systems.

* Jump to:
    * [Cori](#cori_usage)
    * [Theta](#theta_usage)
    * [Titan](#titan_usage)

###<a name="cori_usage"></a>Cori

####Allinea MAP

NERSC's [documentation on
MAP](http://www.nersc.gov/users/software/performance-and-debugging-tools/MAP/)
explains the software environment setup, how to run MAP on Cori using the GUI
client or command-line mode. It also discusses looking at profiling results in
the GUI.

####CrayPAT

NERSC's [documentation on
CrayPAT](http://www.nersc.gov/users/software/performance-and-debugging-tools/craypat/)
explains how to set up and use CrayPAT on Cori. It includes hot to use the
Cray Apprentice2 GUI to visualize performance data and Cray Reveal for
loopmark and source code analysis.

####Intel Advisor

NERSC's [documentation on
Advisor](http://www.nersc.gov/users/software/performance-and-debugging-tools/advisor/)
explains how to use it on Cori, including how to launch jobs and how to use
the GUI to view results.

####Intel VTune Amplifier

NERSC's [documentation on
VTune](http://www.nersc.gov/users/software/performance-and-debugging-tools/vtune/)
explains how to use VTune Amplifier XE on Cori, including module setup,
linking with `-dynamic`, and compiling with `-g`. It also has example job
scripts for collecting different kinds of profiling data and a section on
using the VTUne GUI.  ```



###<a name="theta_usage"></a>Theta

####Allinea MAP

Ryan Huylguin's
[presentation](https://www.alcf.anl.gov/files/hulguin-allinea_ddt_map-v1.pdf)
explains the basic setup and gives example `aprun` syntax for running under
Allinea MAP. You use this syntax in the `aprun` command in your Cobalt job
script.

####CrayPAT

A Cray
[presentation](https://www.alcf.anl.gov/files/wagenbreth-perftools_Argonne_30april2017_v2.0_1.pdf)
given at ALCF describes how to load appropriate modules and build your code to
use CrayPAT, both the "lite" and full versions. You then run your code using
the normal Cobalt job script. Note that you must first load the module to
select the Cray programming environment (and compile/recompile your code with
that environment). The default is the Intel environment, so if you have not
changed it here is a command to switch to the Cray environment:

```
module swap PrgEnv-intel PrgEnv-cray
```

####HPCToolkit

Mark Krentel's [presentation](https://www.alcf.anl.gov/files/hpctoolkit.pdf)
has quick start information for using HPCToolkit on Theta. In the `aprun`
command in your job script, you insert `hpcstruct` before your executable
program name.

####Intel VTune Amplifier

ALCF's [documentation](http://www.alcf.anl.gov/user-guides/vtune-xc40) has
basic steps to use VTune on Theta, with an example run script. It also
explains how to selectively profile a subset of all MPI ranks.

####Tuning and Analysis Utilities (TAU)

For all TAU usage modes, you should first load the TAU module:

```
module load tau
```

The Hands-On section of Sameer Shende's
[presentation](https://www.alcf.anl.gov/files/shende-TAU-ALCF-v1.0.pdf)
illustrates using TAU on Theta via a Cobalt interactive session (`qsub
-I`). You may also run a normal batch job, inserting the `tau_exec` command
before your executable program name in the `aprun` command in your Cobalt
batch script. To use TAU without recompiling your code, you must have linked
it as a dynamic executable (link using `-dynamic`), and you should have
compiled and linked with `-g`. To use with compiler and/or explicit
source-code instrumentation, you should compile using the TAU compiler
wrappers as explained in the presentation.


###<a name="titan_usage"></a>Titan

####CrayPAT

OLCF's [documentation on
CrayPAT](https://www.olcf.ornl.gov/kb_articles/software-craypat/) includes a
10-step usage guide for basic analysis of your program on Titan using
CrayPAT. It explains using the `pat_report` tool for text reports and
Apprentice2 for GUI analysis. There are more details on the [OLCF CrayPAT
software page](https://www.olcf.ornl.gov/kb_articles/software-craypat/).

####NVPROF

OLCF's [documentation on accelerator performance
tools](https://www.olcf.ornl.gov/kb_articles/gpu-performance-tools/) explains
how to set up your environment and run using the NVPROF profiler to gather
performance data from the GPUs.

####Tuning and Analysis Utilities (TAU)

OLCF's [documentation on accelerator performance
tools](https://www.olcf.ornl.gov/kb_articles/gpu-performance-tools/) briefly
explains how use TAU profiling and tracing tools for CPU-GPU hybrid
programs. There are more details on the [OLCF TAU software
page](https://www.olcf.ornl.gov/kb_articles/software-tau/).

