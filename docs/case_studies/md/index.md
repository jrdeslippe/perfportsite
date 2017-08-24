# Developing a new molecular dynamics code with an eye towards portability

[Classical molecular dynamics](https://en.wikipedia.org/wiki/Molecular_dynamics) 
has become a ubiquitous
computational modeling tool for a number of disciplines,
from biology and biochemistry, to geochemistry and polymer
physics.  Due to intense efforts from a
number of developers over the past 50 years, several MD programs have been highly successful in achieving commendable
efficiency and overall performance.

The classical molecular dynamics algorithm involves three
main components: the integration step, the calculation of
short-range forces, and the calculation of long-range
forces. The integration step is generally the quickest part
of the calculation, and as it has some memory-intensive
aspects, is often calculated using the CPU, in
implementations using heterogeneous architectures. The
long-range force calculation, in most implementations,
involves an Ewald sum. This requires the use of Fourier transform
methods, which are fast for smaller systems, but do not
scale well for large systems. This is an active area of
development and is not addressed here. The
major bottleneck for all system sizes is the short-range
non-bonded forces (SNFs) calculation, as it involves a sum
of pairwise interactions over multiple subsets of the
particle space.


As part of our portable performance studies, we have written
a new SNF kernel, wherein we use directives (OpenACC) to
implement the parallel steps of the computation. We have also produced  an alternate
implementation where matrix-matrix multiplication is used to 
calculate pairwise distances in the SNF calculation. This
alternate implementation, though requiring more
floating-point operations, is shown to perform well because
of the performance of platform-specific BLAS libraries.  

Details of the MD experiment can be found in this
[report](./md.pdf).



