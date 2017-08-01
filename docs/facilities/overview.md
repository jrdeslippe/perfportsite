#This should be high level overview of differences at centers - we can then cover more in comparison

The [Advanced Scientific Computing Research](https://science.energy.gov/ascr/)
program in DOE Office of Science sponsors three computing facilities - [the
Argonne Leadership Computing Facility](https://www.alcf.anl.gov/) (ALCF), the
[Oak Ridge Leadership Computing Facility](https://www.olcf.ornl.gov/) (OLCF),
and the [National Energy Research Scientific Computing
Center](https://www.nersc.gov/) (NERSC). Below we summarize the technical
specifications of the current or upcoming computing systems deployed at each
facility.

| System   | Facility  | Model     | Processor                          | Accelerator             | Nodes   | Perf. Per Node  | Peak Perf. |
|:--------:|:---------:|:---------:|:----------------------------------:|:-----------------------:|:-------:|:---------------:|:----------:|
| [Aurora](http://aurora.alcf.anl.gov/)   | ALCF      | Intel     | Intel Xeon Phi (3rd gen)    | (none)                  | >50 000 | ?               | ?          |
| [Cori](http://www.nersc.gov/users/computational-systems/cori/configuration/)     | NERSC     | Cray XC40 | Intel Xeon Phi (2nd gen) | (none)                  | 9 688   | 2.6 TF          | 30 PF      |
| [Summit](https://www.olcf.ornl.gov/summit/)   | OLCF      | IBM       | IBM POWER9                         | NVIDIA Tesla ("Volta")  | ~4 600  | > 40 TF         | ?          |
| [Theta](http://www.alcf.anl.gov/user-guides/computational-systems#theta-(xc40))    | ALCF      | Cray XC40 | Intel Xeon Phi (2nd gen) | (none)                  | 3 624   | 2.6 TF          | 10 PF      |
| [Titan](https://www.olcf.ornl.gov/computing-resources/titan-cray-xk7/)    | OLCF      | Cray XK7  | AMD Opteron ("Interlagos")         | NVIDIA Tesla ("Kepler") | 18 688  | 1.4 TF          | 27 PF      |
