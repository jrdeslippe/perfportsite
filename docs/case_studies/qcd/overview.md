# Brief Introduction to Lattice QCD

[Lattice QCD](https://en.wikipedia.org/wiki/Lattice_QCD) is a numerical method to evaluate [Quantum Chromodynamics (QCD)](https://en.wikipedia.org/wiki/Quantum_chromodynamics),
the theory of the strong interaction which binds quarks into nucleons and nucleons into nuclei,
in a straightforward way with quantifiable uncertainties. It is non-perturbative and thus has access
to energy regimes where common analytical methods fail.
In orer to transform continuum QCD to Lattice QCD, one first rotates the time axis to imaginary times which 
transforms the 4-dimensional [Minkowski space](https://en.wikipedia.org/wiki/Minkowski_space) into Eculidian $\mathbb{R}^4$,
followed by discretizing space-time by introducing a grid-constant $a$ as well as making the volume finite with side extents $L$.

The most expensive part of Lattice QCD is the calculation of so-called quark propagators, i.e.
computing the solution of the Dirac equation
$(/\!\!\!\!D\,-m)\psi = \eta$, where $m$ is the mass of the particle, $\eta$ is a given vector (i.e. the so-called *source*)
and $/\!\!\!\!D$ is a so-called gauge-covariant, Fermion derivative operator. There are many possibilities for discretizing the
continuum version of the Fermion derivative operator and the most common one are the so-called [Wilson fermions](). In this discretizaton,
the operator, also called Wilson operator, is given by
$/\!\!\!\!D(x,y) = \sum\limits_{\mu=0}^3 U_{\mu}(x)(1-\gamma_{\mu})\delta_{y,x+\hat{\mu}}+U^{\dagger}_{\mu}(x-\hat{\mu})(1+\gamma_{\mu})\delta_{y,x-\hat{\mu}}$.
Here, $\hat{\mu}$ denotes a displacement in $\mu$-direction by one lattice site. $U_{\mu}(x)$ are the so-called links connecting the neighboring sites $x$ and $x+\hat{\mu}$ in a gauge-covariant way. They are elements of $SU(3)$, i.e. they can be described by 3x3 complex-valued, [unitary matrices](https://en.wikipedia.org/wiki/Unitary_matrix) with unit [determinant](https://en.wikipedia.org/wiki/Determinant). The $\gamma_{\mu}$ are sparse 4x4 matrices and are the generators of the so-called [Dirac algebra](https://en.wikipedia.org/wiki/Dirac_algebra), a 4-dimensional spin [Clifford algebra](https://en.wikipedia.org/wiki/Clifford_algebra).
The Wilson operator couples only neighboring sites and is thus ultra-local.

In modern lattice calculations, the overwhelming majority of CPU time is spent on solving the Dirac equation. Therefore,
most optimization efforts focus on optimizing the Wilson operator as well as solvers which use this operator as their kernel.
It is thus importanto to find out whether the Wilson operator can be implemented in a performance portable way.