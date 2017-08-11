Measuring Rooflin Quantities on NVIDIA GPUs

It is possible to measure roofline quantities for a kernel on a GPU using the NVProf tool as described [here](/facilities/tools.md). 

In general, one wants to compute arithmetic intensity as well as FLOPS which involves three quantities:
 
1. Number of floating point operations
2. Data volume moved to and from DRAM
3. The runtime in seconds

Here are the steps to do this with NVProf:

1. Use gpu-trace mode to collect the time spent in the kernel you are interested in

```shell
command: nvprof --print-gpu-trace ./build/bin/hpgmg-fv 6 8
output: 
Time(%)      Time     Calls    Avg           Min                Max           Name
 51.96%  2.52256s   1764  1.4300ms  1.4099ms  1.4479ms      void smooth_kernel<int=7, int=16, int=4, int=16>(level_type, int, int, double, double, int, double*, double*)
```

2. Use the metric summary mode (you can specify the target kernel) to collect information such as:

1. Floating point ops
2. DRAM R/W transactions
3. DRAM R/W throughput

nvprof command to watch:

FP= double precision ops 

DR/DW= dram read/write transactions

TR/TW= dram read/write throughput

for the CUDA kernel -- smooth_kernel:

```shell
nvprof  --kernels "smooth_kernel" --metrics flop_count_dp  --metrics dram_read_throughput  --metrics dram_write_throughput --metrics dram_read_transactions --metrics 
dram_write_transactions ./build/bin/hpgmg-fv 6 8 
```

To compute Arithmetic Intensity you can use the following methods:

Method I:  

FP / ( DR + DW ) * (size of transaction = 32 Bytes)

Method II:

FP / (TR + TW) * time taken by kernel (computed by step 1)
