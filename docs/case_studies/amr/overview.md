Thorsten / Brian to Write

# Overview of BoxLib/AMReX

[BoxLib](https://github.com/BoxLib-Codes/BoxLib) is a framework for developing
parallel, block-structured, adaptive mesh refinement (AMR) applications. It is
written primarily in C++, and enables scientific application development
through compute kernels written primarily in Fortran. Through the [Exascale
Computing Project](https://exascaleproject.org/exascale-computing-project/)'s
[Block Structured Adaptive Mesh Refinement Co-Design
Center](https://crd.lbl.gov/news-and-publications/news/2016/new-article-pageberkeley-lab-to-lead-amr-co-design-center-for-does-exascale-computing-project/),
BoxLib has since been superseded by
[AMReX](https://www.github.com/AMReX-codes/amrex). Both frameworks are publicly
available. The DOE COE for Performance Portability began prior to the formation
of the Co-Design Center; consequently,the efforts described here focus on
BoxLib, although the functionality described here is largely the same between
the two frameworks.

BoxLib contains a wide variety of functionality:

 * boundary condition exchange among boxes
 * load balancing through regridding boxes among MPI processes
 * metadata operations such as computing volume intersections among boxes
 * memory management through pool allocators

In addition these, BoxLib also provides linear solvers which use geometric
multigrid methods to solve problems on both cell-centered and nodal data. Our
performance portability efforts described here focus on the cell-centered
solver, which is algorithmically simpler than the nodal solver.
