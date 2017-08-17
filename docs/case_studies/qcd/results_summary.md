# Results Summary

In order to assess the performance on KNL and GPU architectures, we compare against the highly optimized libraries [QPhiX](https://github.com/JeffersonLab/qphix) and [QUDA](https://github.com/lattice/quda) respectively. Those two codes should set the upper bar of what can be achieved on the corresponding architectures for the given problem. Note that these libraries additionally employ some algorithmic improvements which we did not use in our simple test case. However, it is possible to switch most of these optimizations off to allow for better comparisons with our portable code. The vectorization in both frameworks is performed over lattice sites and not over multiple right hand sides as in our testcase. Therefore, we expect those frameworks to show better performance for the single right hand side case, whereas in the multiple right hand side case those benefits are expected to shrink.

On the CPU, we additionally compare our code to a plain C++ as well as to a legacy SSE-optimized Wilson dslash operator, both available through the [Chroma framework](https://jeffersonlab.github.io/chroma/). Those two codes should act as some kind of lower bar for our performance comparisons. Because of different vetorization behaviour in our kokkos dslash. we split our results summary into two parts, i.e. one for the single and one for the multiple right-hand-sites case.

## Single Right-Hand-Side
The achieved performance is shown in the figure below.

![Kokkos Dslash SRHS](images/kokkos_srhs_results.png)


## Multiple Right-Hand-Sides

The plot shows that our Kokkos kernel performs much better on Volta than on Pascal, measured in fraction of what can be acieved by using the optimized QUDA library. This is likely due to the significant overhead of integer arithmetic [Kokkos supposedly inserts into the generated CUDA kernels](./kokkos_implementation.md#index). This issue is mitigated by Voltas new architecture, which offer much more integer operation units than previous GPU architectures.