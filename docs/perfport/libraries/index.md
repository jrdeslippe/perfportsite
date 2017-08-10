# Libraries


The use of scientific libraries to achieve a measure of portable performance 
has been used across many earlier computational platforms. 
The ability to use higher-level abstractions via libraries allows developers to 
concentrate their effort on algorithmic development, freeing them from having to 
devote considerable effort to maximizing performance for many mathematical primitives. The most popular scientific libraries include 
packages designed to solve problems in linear algebra (both dense and sparse), compute fast Fourier transforms (FFT), multigrid 
methods, and initial value problems for ordinary differential 
equations, along with other examples. Some of the best known scientific libraries include:

These tasks often represent a good measure of the computational work to be found in many scientific 
codes. For some codes, almost all of the computational intensity can be found in the use of a
library for, e.g., eigenvalue solution or FFTs. If such a code makes use of libraries for their solution, 
portability is very often assured. Indeed, even if a particular library has not been ported to a new
architecture at a given time, the library source code is often available and can be compiled by the
user on the new platform. However, the best performance is realized when either the library maintainers or
the machine vendor (or both) undertake development to optimize a given library on a particular platform. 
This obvious advantage has been realized by vendors, and for many of the libraries referred to earlier, this 
optimization is done as a matter of course.

Conversely, performance cannot be guaranteed with the same degree of certainty. First, although libraries often 
do encapsulate a good measure of the required work, in most cases this is not **all** of the work, including 
what is often strictly serial work. This fundamental constraint is sometimes exacerbated by the
fact that architecture-specific implementations are evolving, despite the best efforts of both vendors and
library maintainers. 

Codes with obvious "hot spots" can often make immediate use of libraries to acheive performance portability. 
This is often easiest for codes written in Fortran and C, whereas bindings to many libraries in C++ can 
be lacking or somewhat arcane to use. One of the biggest concerns in using libraries for extant codes is 
the frequent requirement to recast data structures used in the code to the format used by the library. 
The best approach to ameliorate this problem is often to simply use a memory copy: The relative cost of the 
copy compared to the work done in the library is often small, and the use of a localized copy obviates the
need to change data structures pervasively throughout the code.  

## Considerations for using libraries for portable performance  

Pros

* Often encapsulate much of the computational intensity found in scientific codes

* Can allow immediate portability under some circumstances

* Performance becomes a task for library authors/maintainers

Cons

* Limited set of portable libraries at present

* May not capture all the important/expensive tasks in a given code  

* Often require recasting data structures to match library requirements

* Opaque interior threading models 

## Some popular scientific libraries available on ASCR facilities

* [BLAS/LAPACK](http://www.netlib.org/lapack/) - dense linear algebra

    * BLAS and LAPACK are often contained in vendor-supplied library collections, like:

        * [MKL](https://software.intel.com/en-us/articles/intel-math-kernel-library-documentation) (Theta, Cori)

        * [Cray LibSci](http://docs.cray.com/cgi-bin/craydoc.cgi?mode=View;id=S-2396-610;idx=books_search;this_sort=title;q=;type=books;title=Cray%20Application%20Developer%27s%20Environment%20User%27s%20Guide) (Theta, Cori, Titan) 

    * In addition, other platform-specific implementations are avaialable, like:

        * [MAGMA](http://icl.cs.utk.edu/magma/) (GPU; Titan)

        * [PLASMA](http://icl.cs.utk.edu/projectsfiles/plasma/html/) (multicore; Theta, Cori)

* [FFTW](http://www.fftw.org/) - Fast Fourier Transform

    - Like LAPACK/BLAS, FFTW-like APIs can be found in MKL and ACML

* [PETSc](https://www.mcs.anl.gov/petsc/) - PDE solvers

    - PETSc is much more like a framework, and often requires more extensive code changes to use efficiently 

