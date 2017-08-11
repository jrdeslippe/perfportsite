##Hardware In-Depth

|System-> | [Cori](http://www.nersc.gov/users/computational-systems/cori/configuration/)  |  [Theta](http://www.alcf.anl.gov/user-guides/computational-systems#theta-(xc40))                          | [Titan](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/)             |
|:---:|:--------:|:---------:|:-----------------------:|
| Facility | NERSC | ALCF | OLCF |
| Model | Cray XC40 | Cray XC40 | Cray XK7 |
| Processor | Intel Xeon Phi (2nd gen) | Intel Xeon Phi (2nd gen) | AMD Opteron ("Interlagos") |
| Specific Processor | ? | [Intel SKU 7230](http://ark.intel.com/products/94034/Intel-Xeon-Phi-Processor-7230-16GB-1_30-GHz-64-core) | AMD Opteron 6274 |
| Processor Cores | 68 | 64 | 16 CPU cores (in 8 physical modules) |
| Processor Base Frequency | ? | 1.3 GHz | 2.2 GHz |
| Processor Max Frequency | ? | 1.5 GHz | 3.1GHz (disabled) |
| Processor On-Package Memory | 16 GB MCDRAM | 16 GB MCDRAM | n/a |
| Processor DRAM | ? | 192 GB DDR4 | 32 GB  |
| Accelerator | (none) | (none) | NVIDIA Tesla ("Kepler") K20X |
| Nodes | 9 688  | 3 624 | 18 688 |
| Perf. Per Node | 2.6 TF | 2.6 TF | 1.4 TF |
| Node local storage | ? | 128 GB SSD | n/a |
| External Burst Buffer | ? | n/a | n/a |
| Parallel File System | ? | 10 PB Lustre | 28 PB Lustre  |
| Interconnect | ? | Cray Aries | Cray Gemini |
| Topology | ? | Dragonfly | 3D torus |
| Peak Perf | 30 PF | 10 PF | 27 PFF |


##Software Environment

|System-> | [Cori](http://www.nersc.gov/users/computational-systems/cori/configuration/)  |  [Theta](http://www.alcf.anl.gov/user-guides/computational-systems#theta-(xc40))                          | [Titan](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/)            |
|:---|:--------|:---------|:-----------------------|
| Software environment management | [modules](http://www.nersc.gov/users/software/nersc-user-environment/modules/) | [modules](http://www.alcf.anl.gov/user-guides/onboarding-guide#step4) | [modules](https://www.olcf.ornl.gov/support/system-user-guides/titan-user-guide/#172) |
| Batch Job Scheduler | [Slurm](http://www.nersc.gov/users/computational-systems/cori/running-jobs/batch-jobs/) | [Cobalt](http://www.alcf.anl.gov/user-guides/running-jobs-xc40) | [PBS](https://www.olcf.ornl.gov/support/system-user-guides/titan-user-guide/#273) |
| **Compilers** |
| Intel | ? | (*default*) `module load PrgEnv-intel` | `module load PrgEnv-intel` |
| Cray | ? | `module load PrgEnv-cray` | `module load PrgEnv-cray` |
| GNU | ? | `module load PrgEnv-gnu` | `module load PrgEnv-gnu` |
| PGI | ? | n/a |  (*default*) `module load PrgEnv-pgi` |
| CLANG | ? | `module load PrgEnv-llvm` | n/a |
| **Interpreters** |
| R | ? | `module load cray-R` | `module load r` |
| Python 2 | ? | Cray: `module load cray-python`<br> Intel: `module load intelpython26`  | `module load python_anaconda` |
| Python 3 | ? | Intel: `module load intelpython35`  | `module load python_anaconda3` |
| **Libraries** |
| FFT | ?  | FFTW: `module load fftw` <br> Cray FFTW: `module load cray-fftw` <br> Intel MKL: *automatic with Intel compilers* |  FFTW: `module load fftw` <br> Cray FFTW: `module load cray-fftw` |
| [Cray LibSci](http://www.nersc.gov/users/software/programming-libraries/math-libraries/libsci/) | ? | `module load cray-libsci` | `module load cray-libsci` |
| [Intel MKL](https://software.intel.com/en-us/articles/intel-math-kernel-library-documentation) | ? | *automatic with Intel compilers* | *automatic with Intel compilers* |
| [Trilinos](https://trilinos.org/) | ? | `module load cray-trilinos` | `module load cray-trilinos` |
| [PETSc](https://www.mcs.anl.gov/petsc/) | ? | `module load cray-petsc` | `module load cray-petsc` |
| SHMEM | ? | `module load cray-shmem` | `module load cray-shmem` |
| [memkind](http://memkind.github.io/memkind/) | ? | `module load cray-memkind` | n/a |
| **I/O Libraries** |
| HDF5 | ? | `module load cray-hdf5` | `module load cray-hdf5` |
| NetCDF | ? | `module load cray-netcdf` | `module load cray-netcdf` |
| Parallel NetCDF | ? | `module load cray-parallel-netcdf` | `module load cray-parallel-netcdf` |
| **Performance Tools and APIs** |
| Intel VTune Amplifier | ? | `source /opt/intel/vtune_amplifier_xe/amplxe-vars.sh` | n/a |
| CrayPAT | ? | `module load perftools` | `module load perftools` |
| [PAPI](http://icl.utk.edu/papi/) | ? | `module load papi` | `module load papi` |
| [Darshan](http://www.alcf.anl.gov/user-guides/darshan) | n/a? | `module load cray-memkind` | `module load darshan` |
| **Other Packages and Frameworks** |
| [Shifter](http://www.nersc.gov/research-and-development/user-defined-images/) |? | `module load shifter` | n/a |

##Compiler Wrappers

Use these wrappers to properly cross-compile your source code for the compute
nodes of the systems, and bring in appropriate headers for MPI, etc.

|System-> | [Cori](http://www.nersc.gov/users/computational-systems/cori/configuration/)  |  [Theta](http://www.alcf.anl.gov/user-guides/computational-systems#theta-(xc40))                          | [Titan](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/)             |
|:---:|:--------:|:---------:|:-----------------------:|
| C++ | ? | `CC` | `CC` |
| C | ? | `cc` | `cc` |
| Fortran | ? | `ftn` | `ftn` |


##Job Submission


###Cori

####Job Script

####Job Submit Command


###[Theta](https://www.alcf.anl.gov/XC40-system-runnning-jobs)

####Job Script

```bash
{!facilities/theta_script.sh!}
```

The `#COBALT -t 30` line indicates 30 minutes runtime. Generally, `#COBALT`
lines are equivalent to specifying `qsub` command-line arguments.

####Job Submit Command

```
qsub -n 512 ./theta_script.sh
```
The `-n 512` argument requests 512 nodes.


###Titan

####Job Script

```bash
{!facilities/titan_script.sh!}
```


####Job Submit Command

```
qsub -l nodes=512 ./theta_script.sh
```
The `-l nodes=512` argument requests 512 nodes (this can also be put in the batch script).

