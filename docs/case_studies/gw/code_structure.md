# Code structure

## Original code structure

The inner loops of the FORTRAN-90 code have the following form. 

```FORTRAN
!$OMP DO reduction(+:achtemp)
do igp = 1, ngpown
  ...

  do iw=1,3 ! Original Inner Loop Bad for Vectorization

    ...

    do ig = 1, ncouls

      delw = array2(ig,np) / (wxt(iw,np) - array1(ig,igp))
      ...
      scht = scht + ... * delw * array3(ig,igp) 

    enddo ! loop over g

    achtemp(iw) = achtemp(iw) + 0.5D0*scht*vcoul(igp)

  enddo   

enddo 
```

where, in the production code, we block the `ig` loop around the `iw` loop in order to gain data reuse. However, the inner 'ig' loop is left appropriately 
long to 
get efficient vector performance - typically block sizes of around 256 are used, which is many vector lengths on a KNL processor.

## Portability considerations

There are essentially three hot-arrays in this code, for convenience named array1, array2, array3 corresponding to the three complex-double precision arrays 
on the equation in the previous page: $M$, $\Omega$ and $\tilde{\omega}$. It will be important to place these in the fastest memory tier. 

The data-structures are generally double-precision complex. This is a native FORTRAN type, but is less standard in C/C++. Performance additionally requires 
a fast vectorizable-divide instruction for complex-numbers or a suitable work-around. This was an issue only the earlier generation Xeon-Phi, Knights 
Corner, for example.
