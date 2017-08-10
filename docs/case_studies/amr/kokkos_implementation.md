# Kokkos Implementation

The first difficulty with porting the BoxLib GMG to Kokkos is that most of the kernels are written in Fortran. For Kokkos, we need those in C++ so we have rewritten these kernels accordingly. As an example, hre is the GSRB kernel in C++

For the sake of simplicity, we work directly with the fabs and not with the data pointers as we do in Fortran, so that we can use the access operator to index into our data containers. 