# Introduction to Lattice QCD

[Lattice QCD](https://en.wikipedia.org/wiki/Lattice_QCD) is a numerical method to evaluate [Quantum Chromodynamics (QCD)](https://en.wikipedia.org/wiki/Quantum_chromodynamics),
the theory of the strong interaction which binds quarks into nucleons and nucleons into nuclei,
in a straightforward way with quantifiable uncertainties. It is non-perturbative and thus has access
to energy regimes where common analytical methods fail.
In order to transform continuum QCD to Lattice QCD, one first rotates the time axis to imaginary times which 
transforms the 4-dimensional [Minkowski space](https://en.wikipedia.org/wiki/Minkowski_space) into Euclidean $\mathbb{R}^4$. Then,
euclidean space-time is discretized by introducing a lattice spacing $a$ as well as finite volume with side extents $L$.

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
It is thus important to find out whether the Wilson operator can be implemented in a performance portable way.

## Implementation
In this section we will briefly discuss architecture-independent implementation details of the Wilson operator. 

### Multiple Right Hand Sides
An efficient way to increase the arithmetic intensity in sparse linear systems is to solve for multiple right hand side (MRHS) vectors simultaneously. Working on a number of right hand sides which fits SIMD registers, is also a quick and easy way to explore effects of vectorization in an implementation.
Further, this case is also relevant to many lattice QCD applications -- in some cases O(10^5^)-O(10^6^) systems may need to be solved with the same gauge configuration as input. For all these reasons, we have also implemented this version of the operator in our small test case. 

### Arithmetic Intensity
The arithmetic intensity per lattice site for the Wilson operator can be computed as follows:

$$
\frac{\#\mathrm{Flops}}{\#\mathrm{Bytes}} = \frac{1320}{8G + (9-R+r)S},
$$

where $G$ is the size of a gauge link, $S$ the size of a spinor, $R$ the nearest neighbor spinor reuse factor (assuming that caches which are closer to the processor than the level of memory where the data resides are infinitely fast) and $r=0$ if streaming stores are used and $r=1$ otherwise (read-for-write). The constant factors account for the fact that in 4 dimensions, each lattice site has 8 neighbors and thus 8 links and spinors needs to be read from memory and one spinor needs to be written. If streaming stores are not used, the output spinor needs to be read into cache first and thus the total number of spinors transferred per computed site will be 10 in this case. Whereas the spinor always consists of 12 complex numbers (3 color and 4 spin components), the gauge links G can be in theory compressed to 8 real numbers by using properties of [Lie algebras](https://en.wikipedia.org/wiki/Lie_algebra) along with the generators of $SU(3)$. However, this can require trigonometric functions whose performance may be strongly hardware dependent, so that usually a less aggressive form of compression is used by simply dropping one row or column of the gauge link and reconstruct it on the fly when needed. This format is called *12-compression* and widely used in modern Wilson operator implementations. In our simple test case however, we do not use this kind of compression and thus the expected arithmetic intensity is between $0.86$ $(R=0,\,r=1,\,G=18)$ and $1.72$ $(R=7,\,r=0,\,G=18)$ for single precision.

We have applied one additional common optimization to our code known as the spin-projection trick:

* The terms $( 1 \pm \gamma_\mu)$ in the spin-indices act as a projector in spin, and applying them to an input vector reduces the number of independent spin-degrees of freedom in the result from 4 to 2 (with the remaining two being related to the 2 independent ones through trivial operations such as - sign, or multiplication by complex $i$, or similar). Hence, because multiplication in spin by the projectors and in color by the gauge-link matrices commute, one typically first projects an input 4-spinor to a 2-component object known as a *half spinor*. The 3x3 gauge link matrix is then multiplied to the 3-color vector object for each of the two spin components. Finally the remaining 2 spin components are *reconstructed* by applying the necessary trivial transformation. Spin projection depends on direction $\mu$, but not on the lattice site indices. 

* In order to be able to utilize vector registers on architectures like Intel Xeon Phi Knight's Landing, we attempt to vectorize over the multiple-right sources in a 'multiple-right-hand side' application (MRHS) of the operator
