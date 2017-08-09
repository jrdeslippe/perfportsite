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
