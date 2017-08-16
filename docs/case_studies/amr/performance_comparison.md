# Performance Comparison

Here we summarize the performance of the BoxLib geometric multigrid solver when
implemented with the various performance portable solutions described on this
site. The various kernels mentioned here are discussed in detail on the
[geometric multigrid](./multigrid.md) page.

## Gauss-Seidel red-black
### (FILL THESE IN WITH REAL DATA)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Kokkos functor (no Views) | POWER9 | 4242.0 |
| Kokkos functor (no Views) | Pascal | (n/a) |
| Kokkos functor (no Views) | Kepler | (n/a) |
| Kokkos functor (no Views) | KNL | 42424242.0 |
| Kokkos functor (with Views) | Pascal | 42424242.0 |
| OpenMP 4.x `target` | Pascal | 42424242.0|
| OpenMP 3.x `parallel do` | Pascal | (n/a) |
| OpenMP 3.x `parallel do` | KNL | 424242.0 |
| RAJA | Pascal | 4242424242.0|

## Restriction
### (FILL THESE IN WITH REAL DATA)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Kokkos functor (no Views) | POWER9 | 4242.0 |

## Prolongation
### (FILL THESE IN WITH REAL DATA)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Kokkos functor (no Views) | POWER9 | 4242.0 |

## Bottom solve
### (FILL THESE IN WITH REAL DATA)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Kokkos functor (no Views) | POWER9 | 4242.0 |

## Complete solver
### (FILL THESE IN WITH REAL DATA)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Kokkos functor (no Views) | POWER9 | 4242.0 |
