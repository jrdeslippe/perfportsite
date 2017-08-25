# Summary and Recommendations

We summarize below some of our high-level findings from the survey of available performance-portability options, the case-studies from the Office of Science 
workload and from the outcome of recent DOE performance portability workshops.

## Comparison of Leading Approaches

|Approach|Benefits|Challenges|
|:------------:|:-------------------:|:------------:|
|Libraries  | Highly portable, not dependent on compiler implementations. | Many GPU libraries (e.g. CUFFT) are C only (requiring explicit interfaces to use in FORTRAN) and don't have common interfaces. May lock-in data layout. In many cases libraries don't exist for problem. |
|OpenMP 4.5 | Standardized. Support for C, C++, FORTRAN and others. Simple to get started. | Limited expressibility (particularly on GPUs). Lacks "views". Reliant on quality of compiler implementation - which are generally immature on both GPU and CPU systems. |
|OpenACC    | Standardized. Support for C, C++, FORTRAN. | Limited support in compilers, especially free compilers (e.g. GNU).  |
|Kokkos     | Allows significant expressibility (particularly on GPUs.) | Only supports C++. Vector parallelism often left-out on CPUs. |
|Raja       | Allows incremental enhancements to codes. Many back-ends. | Only supports C++. Lacks data "views" for more advanced portability requirements. | 
|DSLs       | Highest expressibility for appropriate problems | Limited to only a small number of communities. Needs to be maintained and supported for new architectures. |

## Recommendations

At present, the reality is that the options for writing performance portable code are limited in scope and are evolving 
rapidly (see individual approach pages for lists of pros and cons). Therefore, as we see in our case studies, it is likely some 
level of code divergence (`IFDEF` etc.) will be necessary to achieve code that performs near its ceiling on all of Cori, Theta, Titan and Summit. 

However, we've seen that performance-portable approaches and implementations are becoming more and more possible. This rate of 
improvement makes this a good time to evaluate these approaches in your application with an eye towards devising a long-term strategy. 

In general, we have the following recommendations for pursuing performance portable code:

0. Actively profile your application using our suggested tools to make sure you have identified a minimal set of performance critical regions. We recommend 
that you read over the [strategy page](http://performanceportability.org/perfport/strategy/) page and consider your hotspots map to different strategies 
layed out. Additionally, before diving into a particular performance portability approach, we recommend making sure your code is using code software-engineer 
practices and that performance-critical regions are abstracted from the bulk of the application.

1. If a well-supported library or DSL is available to address your performance critical regions, use it.

2. If you have an existing code that is *not* written in C++, evaluate whether OpenMP 4.5 can support your application with minimal code differences.
OpenACC is another possible path, and might be appropriate if you need to interoperate with a limited amount of GPU-specific code (e.g. a small amount of CUDA
that is used in a particularly performance-sensitive piece of code). However, the default level of maturity for OpenACC on the non-GPU platforms is an open question. 

3. If you have an existing code that *is* written in C++, evaluate whether Kokkos, or Raja and OpenMP 4.5 (more incremental) can support your application with minimal code differences, 
considering the above discussion on strategy and the pros and cons for each approach. 

4. Reach out to your DOE SC facility with use cases and deficiencies in these options so that we can actively push for changes in the upcoming 
framework releases and advocate in the standards bodies.

