# slow5-pod5-bench

In this repository, we benchmark the S/BLOW5 format vs POD5 format using the C API (actually C++). C is closer to the file system than high-level languages like Python and therefore in my opinion it is a better choice to benchmark a file format. When using high level languages like Python, data type conversion that happens under the hood can dominate the execution time, thus would not be representative of the file format performance. However, despite being close to the file system, even in the C API, this will be the case to a certain degree. That is, the library implementation and optimisations done would affect the runtime considerably and if that is the case we will end up comparing the implementation rather than the file format. See caveats below before interpreting the results.


- [experiment conditions](docs/conditions.md)
- [experiment setup](docs/exp.md)
- [results](docs/res.md)
- [misc](docs/misc.md)


## Benchmark details

**UPDATE**
Accessing all the signal data and associated parameters required for pico-ampere conversion. This mimics a typical basecalling workflow. We load a batch of reads from the disk, decompress and parse them into memory arrays; do the processing (in this case I just convert the raw signal to picoampere and sum them up); and, output the sum. Only the time for loading a batch of reads from the disk, decompressing and parsing them into memory arrays is measured.


### Code (outdated)

The benchmark code for SLOW5 is available in the [slow5 subdirectory](slow5/README.md)

The benchmark code for POD5 is available in the [pod5 subdirectory](pod5/README.md)


 ## Caveats


- Furthermore, doing a perfect disk I/O benchmark is very tricky due to the effects of different levels of disk caches, other programmes running in the background, etc. I have tried to do the benchmarks with equal conditions as much as possible, but still it is not perfect. For instance, I clean the Linux O/S disk cache before each experiment, however, I cannot clean the hardware cache in the RAID controller, if any.


