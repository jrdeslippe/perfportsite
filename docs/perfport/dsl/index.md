# Domain-Specific Languages (DSLs)

##Introduction 

Domain-Specific Languages (DSLs) offer the possibility of expressing computation 
at a very high level of abstraction, rendering the mechanics of running on complex 
modern platforms much more tractable. Given the level of abstraction afforded by DSLs, they
can be used to produce very portable code. 
But, the performance of a DSL relies on the ability of the
compilers and runtime to effectively exploit architectural details (like the hardware 
and software environments) to carry out the high-level operations specified by the DSL programmer. 

The actual implementation of DSLs can include annotations that are used to extend a general purpose
language (e.g. C or Fortran) or DSLs that are embedded in higher-level languages like Lua, Python, or R.  

Given the current state-of-the-art for DSLs, they are seldom adopted for new code projects, except
as proof-of-principle exercises. Nevertheless, several HPC DSLs do exist, and if their structure is
congruent to a particular problem or set of problems, experimentation with this programming model 
could prove fruitful. 

## Example DSLs for HPC

* [Ebb](http://ebblang.org/) is a DSL for the solution of partial differential equations on meshes. 

* [AMRStencil](https://crd.lbl.gov/departments/applied-mathematics/ANAG/research/d-tec-amrstencil/) is a DSL to implement solvers on AMR meshes.

* [QDP++](http://usqcd-software.github.io/qdpxx/) is a data-parallel programming environment for Lattice QCD.

* [The Tensor Contraction Engine](http://www.csc.lsu.edu/~gb/TCE/) is a DSL that allows chemists to specify the computation of tensor contractions encountered in many-body quantum calculations.

