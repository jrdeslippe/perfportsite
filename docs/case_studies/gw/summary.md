# BerkeleyGW Case Study Summary

## Performance Comparisons
### Cori (Intel compilers)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Fortran (sequential) | KNL | 973.5 |
| C++     (sequential) | KNL | 1193.9 |
| Fortran (OpenMP 3.0) | KNL | 12.7 |
| Fortran (OpenMP 4.5) | KNL |  |
| C++     (OpenMP 3.0) | KNL | 12.8 |
| C++     (OpenMP 4.5) | KNL | 16.4 |
| Kokkos  (OpenMP)     | KNL | 34.2 |

### SummitDev (GCC compilers)
| Approach | Architecture| Execution time (s) |
|:--------:|:-----:|------:|
| Fortran (sequential) | PowerPC | 935.9|
| C++     (sequential) | PowerPC | 12363.5|
| Fortran (OpenMP 3.0) | PowerPC | 41 |
| Fortran (OpenMP 4.5) | PowerPC |  |
| C++     (OpenMP 3.0) | PowerPC | 70.2 |
| C++     (OpenMP 4.5) | PowerPC |  |
| Kokkos  (OpenMP)     | PowerPC | 17.03  |
| Kokkos  (CudaUVM)    | Pascal  | 3.93 |
| Kokkos  (Cuda)       | Pascal  | |

## Lessons Learned
### C++ vs Fortran performance with complex numbers
Fortran natively supports complex numbers which is a huge advantage when it comes to the performance compared to C++.
The sequential version of C++ is 1.5x times slower compared to its fortran counterpart.
We are sure that it is the performance of complex numbers that gives this boost in the fortran code as when the same set of operations are repeated with datatypes such as a float or double both codes
give the same performance.

### C++ complex number reduction
OpenMP does not support the reduction of complex numbers in C/C++.
There are two ways to achieve the desired result,
* Reduce the real and imaginary complex numbers separately.
* Update the results local to each thread parallely and then accumulate the results later after the loop.

The first method is both inelegant and performs worse than the second version.
In the second method we can also vectorize the step of accumulating the results from threads.
