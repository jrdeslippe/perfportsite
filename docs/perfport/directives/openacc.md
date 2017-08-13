# OpenACC

OpenACC is a set of standardized, high-level pragmas that enable C/C++ and Fortran programmers 
to exploit parallel (co)processors, especially GPUs. OpenACC pragmas can be used to annotate 
codes to enable data location, data transfer, and loop or code block parallelism.
 
Though OpenACC has much in common with OpenMP, the syntax of the directives is different. 
More importantly, OpenACC can best be described as having 
a *descriptive* model, in constrast to the more *prescriptive* model presented by OpenMP.
This difference in philosophy can most readily be seen by, e.g.,  comparing the ``acc loop`` directive
to the OpenMP implementation of the equivalent construct. In OpenMP, the programmer has responsibility 
to specify how the parallelism in a loop is distributed (e.g., via ``distribute`` and ``schedule`` clauses). 
In OpenACC, the runtime determines how to decompose the iterations across gangs or workers and vectors.
At an even higher level, an OpenACC programmer can use the ``acc kernels`` construct to allow the compiler complete freedom 
to map the available parallelism in a code block to the available hardware.




## OpenACC at a glance

Some of the most important  data and control clauses for two of the most 
used constructs in OpenACC programming - ``$acc parallel`` and ``$acc kernels`` - are 
listed below. The data placement and movement clauses also appear in ``$acc data`` constructs.
``$acc loop`` provides control of parallelism similarly to ``$acc parallel`` but provides loop-level control. 

Much more detail can be found at:

* [openacc.org](https://www.openacc.org/)

* [OpenACC Best Practices Guide](www.openacc.org/sites/default/files/inline.../OpenACC_Programming_Guide_0.pdf)

* [NVIDIA OpenACC resources](https://developer.nvidia.com/openacc)

* [OLCF Accelerator Programming Guide; Directive Programming](https://www.olcf.ornl.gov/support/system-user-guides/accelerated-computing-guide/#371)

* [OLCF Accelerator Programming Tutorials](https://www.olcf.ornl.gov/support/tutorials/) (includes examples of interoperability with CUDA and GPU libraries like CuFFT)


|construct             | important clauses  | description |
|:---|:---|---:|
|``$acc parallel``        
|    |num_gangs(expression)| Controls how many parallel gangs are created  
|    |num_workers(expression)| Controls how many workers are created in each gang 
|    |vector_length(list)| Controls vector length of each worker  
|    |private(list)| A copy of each variable in list is allocated to each gang  
|    |firstprivate(list)| private variables initialized from host  
|    |reduction(operator:list)| private variables combined across gangs
|``$acc kernels`` |  |  |
| | copy(list)| Allocates memory on GPU and copies data from host to GPU when entering region and copies data to the host when exiting region
| | copyin(list) | Allocates memory on GPU and copies data from host to GPU when entering region
| | copyout(list) |  Allocates memory on GPU and copies data to the host when exiting region
| | create(list) | Allocates memory on GPU but does not copy
| | present(list) | Data is already present on GPU from another containing data region

## How to use OpenACC on ASCR facilities

### OLCF

####Using C/C++

PGI Compiler

```
$ module load cudatoolkit
$ cc -acc vecAdd.c -o vecAdd.out
```

Cray Compiler

```
$ module switch PrgEnv-pgi PrgEnv-cray
$ module load craype-accel-nvidia35
$ cc -h pragma=acc vecAdd.c -o vecAdd.out
```

####Using Fortran

PGI Compiler

```
$ module load cudatoolkit
$ ftn -acc vecAdd.f90 -o vecAdd.out
```

Cray Compiler

```
$ module switch PrgEnv-pgi PrgEnv-cray
$ module load craype-accel-nvidia35
$ ftn -h acc vecAdd.f90 -o vecAdd.out
```



