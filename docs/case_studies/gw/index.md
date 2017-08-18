# Overview of BerkeleyGW Case Study

## Science Description

BerkeleyGW is a material science application that predicts the excited-state properties of a wide range of materials from molecules and nanostuctures to 
crystals including systems with defects and complex interfaces. The excited-state properties of materials (properties associated with electrons in states 
above the lowest energy configuration) are important for a number of important energy application including material design of batteries, 
semiconductors, quantum computing devices, photovoltaics and emitting devices among other applications. The BerkeleyGW application is commonly used in 
conjunction with Density Functional Theory (DFT) applications like Quantum ESPRESSO, PARATEC, ABINIT which compute accurately the ground-state properties of 
materials. In BerkeleyGW, the electronic energies are computed as a solution to the so-called Dyson equation:

$$
\left[ -\frac{1}{2}\nabla^2+V_{\rm loc}+\Sigma(E_{n}) \right] \phi_{n}=E_{n}\phi_{n}.
$$

Which is similar in form to the DFT Kohn-Sham equations with the addition of the energy-dependent Self-Energy operator $\Sigma$.

BerkeleyGW contains many similar computational bottlenecks of DFT applications including a significant amount of time spent in dense linear algebra. 
Additionally, similarly to quantum chemistry packages, there are a number of tensor-contractions that cannot be performed in library calls. One such 
occurence is the evaluation of the electron "Self-Energy" within the common General Plasmon Pole approximation:

$$
\Sigma_{n}=
\sum_{n'}\sum_{{\bf GG}'}
M^{*}_{n'n}(-{\bf G})M_{n'n}(-{\bf G}')\frac{\Omega^2_{{\bf GG}'}}
{\tilde{\omega}_{{\bf GG}'}
\left(E\,{-}\,E_{n'}{-}
\tilde{\omega}_{{\bf GG}'}\right)}
v{\left({\bf G}'\right)}
$$

where $M$, $\Omega$ and $\tilde{\omega}$ are precomputed complex double-precision arrays. 

## Implementation

The fact that the denominator in the above queation depends on $n'$, $G$ and $G'$ means it is difficult to write the matrix-reduction using standard 
math-libaries. The standard code is implemented in FORTRAN-90 with MPI+OpenMP, with care given to ensure a vectorizable inner loop. MPI parallelism is 
general used to parallelize over $n$, $n'$, while OpenMP parallelizes the $G'$ loop and the $G$ loop is left for vectorization. Significant data re-use of 
the arrays is possible if many values of $E$ are required. At minimum, we require 3 $E$ values; which leads to an arithmetic intensity of > 1. Initial 
roofline plots for KNL Xeon Processors are shown below. 

<center><img src="gwroofline.png" width=600></center>

The gap between the code performance and the ceiling can be explained by two factors: 1. the code lacks multiply-add balance 2. the divide instruction has a 
multi-cycle latency. 
