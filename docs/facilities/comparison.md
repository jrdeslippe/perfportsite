##Hardware In-Depth

|System-> | Cori  |  Theta                          | Titan             |
|:---:|:--------:|:---------:|:-----------------------:|
|Facility|[NERSC](http://www.nersc.gov/)|[ALCF](http://www.alcf.anl.gov)|[OLCF](http://www.olcf.ornl.gov)|
| Model | [Cray XC40](http://www.nersc.gov/users/computational-systems/cori/configuration/) | [Cray XC40]((http://www.alcf.anl.gov/user-guides/computational-systems#theta-(xc40)) | [Cray XK7](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/) |
|Processor|[Intel Xeon Phi 7250 ("Knights Landing")](https://ark.intel.com/products/94035/Intel-Xeon-Phi-Processor-7250-16GB-1_40-GHz-68-core)|[Intel Xeon Phi 7230 ("Knights Landing")](https://ark.intel.com/products/94034/Intel-Xeon-Phi-Processor-7230-16GB-1_30-GHz-64-core)|[AMD Opteron 6274 ("Interlagos")](https://www.amd.com/Documents/Opteron_6000_QRG.pdf)|
| Processor Cores | 68 | 64 | 16 CPU cores (2668 (896) SP (DP) CUDA cores on K20X GPU) |
| Processor Base Frequency | 1.4 GHz | 1.3 GHz | 2.2 GHz |
| Processor Max Frequency | 1.6 GHz | 1.5 GHz | 3.1 GHz (disabled) |
| On-Device Memory | 16 GB MCDRAM | 16 GB MCDRAM | (6 GB GDDR5 on K20X GPU) |
| Processor DRAM | 96 GB DDR4 | 192 GB DDR4 | 32 GB DDR3 |
|Accelerator|(none)|(none)|[NVIDIA Tesla K20X ("Kepler")](http://www.nvidia.com/content/PDF/kepler/Tesla-K20X-BD-06397-001-v05.pdf)|
| Nodes | 9 688  | 3 624 | 18 688 |
| Perf. Per Node | 2.6 TF | 2.6 TF | 1.4 TF |
| Node local storage | (none) | 128 GB SSD | (none) |
| External Burst Buffer | 1.8 PB | (none) | (none) |
| Parallel File System | 30 PB Lustre | 10 PB Lustre | 28 PB Lustre  |
| Interconnect | Cray Aries | Cray Aries | Cray Gemini |
| Topology | Dragonfly | Dragonfly | 3D torus |
| Peak Perf | 30 PF | 10 PF | 27 PF |


##Software Environment

|System-> | Cori | Theta | Titan |
|:---|:--------|:---------|:-----------------------|
| Software environment management | [modules](http://www.nersc.gov/users/software/nersc-user-environment/modules/) | [modules](http://www.alcf.anl.gov/user-guides/onboarding-guide#step4) | [modules](https://www.olcf.ornl.gov/support/system-user-guides/titan-user-guide/#172) |
| Batch Job Scheduler | [Slurm](http://www.nersc.gov/users/computational-systems/cori/running-jobs/batch-jobs/) | [Cobalt](http://www.alcf.anl.gov/user-guides/running-jobs-xc40) | [PBS](https://www.olcf.ornl.gov/support/system-user-guides/titan-user-guide/#273) |
| **Compilers** |
| Intel | (*default*) `module load PrgEnv-intel` | (*default*) `module load PrgEnv-intel` | `module load PrgEnv-intel` |
| Cray | `module load PrgEnv-cray` | `module load PrgEnv-cray` | `module load PrgEnv-cray` |
| GNU | `module load PrgEnv-gnu` | `module load PrgEnv-gnu` | `module load PrgEnv-gnu` |
| PGI | n/a | n/a |  (*default*) `module load PrgEnv-pgi` |
| CLANG | n/a | `module load PrgEnv-llvm` | n/a |
| **Interpreters** |
| R | gcc + MKL: `module load R` <br> Cray: `module load cray-R` | `module load cray-R` | `module load r` |
| Python 2 | Anaconda + Intel MKL: `module load python/2.7-anaconda` | Cray: `module load cray-python`<br> Intel: `module load intelpython26`  | `module load python_anaconda` |
| Python 3 | Anaconda + Intel MKL: `module load python/3.5-anaconda` | Intel: `module load intelpython35`  | `module load python_anaconda3` |
| **Libraries** |
| FFT | FFTW: `module load fftw` <br> Cray FFTW: `module load cray-fftw` <br> Intel MKL: *automatic with Intel compilers* | FFTW: `module load fftw` <br> Cray FFTW: `module load cray-fftw` <br> Intel MKL: *automatic with Intel compilers* |  FFTW: `module load fftw` <br> Cray FFTW: `module load cray-fftw` |
| [Cray LibSci](http://www.nersc.gov/users/software/programming-libraries/math-libraries/libsci/) | (*default*) `module load cray-libsci` | `module load cray-libsci` | `module load cray-libsci` |
| [Intel MKL](https://software.intel.com/en-us/articles/intel-math-kernel-library-documentation) | *automatic with Intel compilers* | *automatic with Intel compilers* | *automatic with Intel compilers* |
| [Trilinos](https://trilinos.org/) | `module load cray-trilinos` | `module load cray-trilinos` | `module load cray-trilinos` |
| [PETSc](https://www.mcs.anl.gov/petsc/) | `module load cray-petsc` | `module load cray-petsc` | `module load cray-petsc` |
| SHMEM | `module load cray-shmem` | `module load cray-shmem` | `module load cray-shmem` |
| [memkind](http://memkind.github.io/memkind/) | `module load cray-memkind` | `module load cray-memkind` | n/a |
| **I/O Libraries** |
| HDF5 | `module load cray-hdf5` | `module load cray-hdf5` | `module load cray-hdf5` |
| NetCDF | `module load cray-netcdf` | `module load cray-netcdf` | `module load cray-netcdf` |
| Parallel NetCDF | `module load cray-parallel-netcdf` | `module load cray-parallel-netcdf` | `module load cray-parallel-netcdf` |
| **Performance Tools and APIs** |
| Intel VTune Amplifier | `module load vtune` | `source /opt/intel/vtune_amplifier_xe/amplxe-vars.sh` | n/a |
| CrayPAT | `module load perftools-base && module load perftools` | `module load perftools` | `module load perftools` |
| [PAPI](http://icl.utk.edu/papi/) | `module load papi` | `module load papi` | `module load papi` |
| [Darshan](http://www.alcf.anl.gov/user-guides/darshan) | (*default*) `module load darshan` | `module load cray-memkind` | `module load darshan` |
| **Other Packages and Frameworks** |
| [Shifter](http://www.nersc.gov/research-and-development/user-defined-images/) | (*part of base system*) | `module load shifter` | n/a |

##Compiler Wrappers

Use these wrappers to properly cross-compile your source code for the compute
nodes of the systems, and bring in appropriate headers for MPI, etc.

|System-> | Cori | Theta | Titan |
|:---:|:--------:|:---------:|:-----------------------:|
| C++ | `CC` | `CC` | `CC` |
| C | `cc` | `cc` | `cc` |
| Fortran | `ftn` | `ftn` | `ftn` |


##Job Submission


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


###[Titan](https://www.olcf.ornl.gov/support/system-user-guides/titan-user-guide/#273)

####Job Script

```bash
{!facilities/titan_script.sh!}
```


####Job Submit Command

```
qsub -l nodes=512 ./theta_script.sh
```
The `-l nodes=512` argument requests 512 nodes (this can also be put in the batch script).


###[Cori](http://www.nersc.gov/users/computational-systems/cori/running-jobs/)

NERSC provides a [page in the MyNERSC
website](https://my.nersc.gov/script_generator.php) which generates job scripts
automatically based on specified runtime configurations. An example script is
shown below, in which a code uses 512 nodes of Xeon Phi with MCDRAM configured
in "flat" mode, with 4 MPI processes per node and 34 OpenMP threads per MPI
process, using 2 hyper-threads per physical core of Xeon Phi:

###Job Script

```bash
{!facilities/cori_script.sh!}
```
