Measuring Roofline Quantities on NVIDIA GPUs

It is possible to measure roofline quantities for a kernel on a GPU using the NVProf tool which was described [here](/facilities/tools.md). 

In order to plot roofline data, we need to compute arithmetic intensity as well as FLOPS which involves three quantities:
 
1. Number of floating point operations
2. Data volume moved to and from DRAM or cache
3. The runtime in seconds

These can be collected with NVProf using the following steps:

## 1. Use NVProf to collect the time spent 

You can use NVProf to collect time spent in a kernel you are interested in by executing something like the following:

```shell
command: nvprof --print-gpu-trace ./build/bin/hpgmg-fv 6 8
output: 
Time(%)      Time     Calls    Avg           Min                Max           Name
 51.96%  2.52256s   1764  1.4300ms  1.4099ms  1.4479ms      void smooth_kernel<int=7, int=16, int=4, int=16>(level_type, int, int, double, double, int, double*, double*)
```

## 2. Use the NVProf metric summary mode 

You can use this mode and specify the target kernel to collect information such as:

* Floating point ops
* DRAM R/W transactions
* DRAM R/W throughput

An example NVProf command to execute is:

```shell
nvprof  --kernels "smooth_kernel" --metrics flop_count_dp  --metrics dram_read_throughput  --metrics dram_write_throughput --metrics dram_read_transactions --metrics 
dram_write_transactions ./build/bin/hpgmg-fv 6 8 
```

This will produce output like the following for each kernel:

```
    Invocations          Metric Name                     Metric Description                            Min           Max           Avg

    Kernel: void smooth_kernel<int=7, int=32, int=4, int=16>(level_type, int, int, double, double, int, double*, double*)
       1764                  flop_count_dp               Floating Point Operations(Double Precision)   240648192    240648192      240648192
       1764                  dram_read_throughput        Device Memory Read Throughput                 299.98GB/s   307.48GB/s     303.72GB/s
       1764                  dram_write_throughput       Device Memory Write Throughput                40.102GB/s   41.099GB/s     40.578GB/s
       1764                  dram_read_transactions      Device Memory Read Transactions               4537918      4599890        4567973
       1764                  dram_write_transactions     Device Memory Write Transactions              606387       611691         610299
```

You may instead replace the DRAM metrics with L2 metrics to compute a cache-based roofline. For example, replace `dram_write_throughput` with 
`l2_write_throughput`. You can find other available metrics [here](http://docs.nvidia.com/cuda/profiler-users-guide/#metrics-reference).

To compute Arithmetic Intensity you can then use the following equivalent methods:

Method I:  

FP / ( DR + DW ) * (size of transaction = 32 Bytes)

Method II:

FP / (TR + TW) * time taken by kernel (computed by step 1)

where,

FP = double precision ops 

DR/DW= dram read/write transactions

TR/TW= dram read/write throughput

