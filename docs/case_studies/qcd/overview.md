# Introduction to Lattice QCD

[Lattice QCD](https://en.wikipedia.org/wiki/Lattice_QCD) is a numerical method to evaluate [Quantum Chromodynamics (QCD)](https://en.wikipedia.org/wiki/Quantum_chromodynamics),
the theory of the strong interaction which binds quarks into nucleons and nucleons into nuclei,
in a straightforward way with quantifiable uncertainties. It is non-perturbative and thus has access
to energy regimes where common analytical methods fail.
In orer to transform continuum QCD to Lattice QCD, one first rotates the time axis to imaginary times which 
transforms the 4-dimensional [Minkowski space](https://en.wikipedia.org/wiki/Minkowski_space) into Eculidian $\mathbb{R}^4$. Then,
euclidian space-time is discretized by introducing a lattice spacing $a$ as well as finite volume with side extents $L$.

## Wilson Fermions
The most expensive part of Lattice QCD is the calculation of so-called quark propagators, i.e.
computing the solution of the Dirac equation
$(m - /\!\!\!\!D)\psi = \eta$, where $m$ is the mass of the quark, $\eta$ is a given vector (we will refer to this object as *source* or *right-hand-side spinor*)
and $/\!\!\!\!D$ is a so-called gauge-covariant, Fermion derivative operator. There are many possibilities for discretizing the
continuum version of the Fermion derivative operator and the most common one are the so-called [Wilson fermions](). In this discretizaton,
the operator, also called *Wilson operator* or *Dslash* (inspired by the mathematical notation), is given by

$$
/\!\!\!\!D(x,y) = \sum\limits_{\mu=0}^3 U_{\mu}(x)(1-\gamma_{\mu})\delta_{y,x+\hat{\mu}}+U^{\dagger}_{\mu}(x-\hat{\mu})(1+\gamma_{\mu})\delta_{y,x-\hat{\mu}}.
$$

Here, $\hat{\mu}$ denotes a displacement in $\mu$-direction by one lattice site. $U_{\mu}(x)$ are the so-called links connecting the neighboring sites $x$ and $x+\hat{\mu}$ in a gauge-covariant way. They are elements of $SU(3)$, i.e. they can be described by 3x3 complex-valued, [unitary matrices](https://en.wikipedia.org/wiki/Unitary_matrix) with unit [determinant](https://en.wikipedia.org/wiki/Determinant). The $\gamma_{\mu}$ are sparse 4x4 matrices and are the generators of the so-called [Dirac algebra](https://en.wikipedia.org/wiki/Dirac_algebra), a 4-dimensional spin [Clifford algebra](https://en.wikipedia.org/wiki/Clifford_algebra). The indices of $U$ and $\gamma$ are called color and spin indices respectively. 
Note that the Wilson operator couples only neighboring lattice sites and is thus ultra-local.

In modern lattice calculations, the majority of CPU time is spent on solving the Dirac equation. Therefore,
most optimization efforts focus on optimizing the Wilson operator as well as solvers which use this operator as their kernel.
It is thus importanto to find out whether the Wilson operator can be implemented in a performance portable way.

## Implementation
In this section we will briefly discuss architecture-independent implementation details of the Wilson operator. 

### Multiple Right Hand Sides
An efficient way to increase the arithmetic intensity in sparse linear systems is to solve for multiple right hand side (MRHS) vectors simulatenously.
This case is also relevant to many lattice QCD applications so that we have implemented this optimization in our small test case. 

### Arithmetic Intensity
The arithmetic intensity for the Wilson operator can be computed as follows:

$$
\frac{\#\mathrm{Flops}}{\#\mathrm{Bytes}} = \frac{1320}{8G + (9-R+r)S},
$$

where $G$ is the size of a gauge link, $S$ the size of a spinor, $R$ the nearest neighbor spinor reuse factor and $r=0$ if streaming stores are used and $r=1$ otherwise (read-for-write). The constant factors account for the fact that in 4 dimensions, each lattice site has 8 neighbors and thus 8 links and spinors needs to be read from memory and one spinor needs to be written. If no streaming stores are used, the output spinor needs to be read into cache first and thus the total number of spinors transferred per computed site will be 10 in this case. Whereas the spinor always consists of 12 complex numbers (3 color and 4 spin components), the gauge links G can be in theory compressed to 8 real numbers by using properties of [Lie algebras](https://en.wikipedia.org/wiki/Lie_algebra) along with the generators of $SU(3)$. However, this is very expensive so that usually a less aggressive form of compression is used by simply dropping one row or column of the gauge link and reconstruct it on the fly when needed. This format is called *12-compression* and widely used in modern Wilson operator implementations. In our simple test case however, we do not use this kind of compression and thus the expected arithmetic intensity is between $0.86$ $(R=0,\,r=1,\,G=18)$ and $1.72$ $(R=7,\,r=0,\,G=18)$ for single precision.

We have applied two optimizations to our Wilson dslash test code

* we replace the Wilson operator with it's [Schur complement](https://en.wikipedia.org/wiki/Schur_complement), i.e. we use $M_{oo} = m - /\!\!\!\!D_{oe} m^{-1} /\!\!\!\!D_{eo}$ instead of applying $/\!\!\!\!D$ directly. Here, the indices $oo$, $oe$ and $eo$ indicate that the respective operators only couple odd-odd, odd-even or even-odd sites respectively. With this optimization, the modified problem can essentially be solved on a volume half as big as the original problem and the solution easily be reconstructed for the other half.
* we use properties of the Dirac matrices to project the 4-spinors to two pairs of linear dependent 2-spinors before applying the dslash, saving 50% of the required flops.
* we solve for multiple right hand side vectors simultaneously to increase the arithmetic intensity. This optimizations amounts to multiplying the number of flops as well as the number of reads and stores by the number of right hand sides $N$. Since all these vectors should ideally be kept in cache, the effective reuse factor $R$ will drop with increasing $N$. In our testcase we vectorize using SIMD or SIMT over these right hand side vectors, so $N$ should ideally be an integer multiple of the vector/warp size. These two aspects have to be taken into account when optimizing the performance.
