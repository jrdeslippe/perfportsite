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

### 2. Use the roofline model to compare actual to expected performance


