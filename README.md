# slow5-pod5-bench

In this repository, my attempt is to benchmark the S/BLOW5 format vs POD5 format using the C API. C is close to the file system than high-level languages like Python and therefore in my opinion it is a better choice to benchmark the file format. When using high level languages like Python, data type conversion that happens under the hood can dominate the execution time, thus would not be respresetative of the file format performat. Even in the C API this will be the case to a certain degree. Even though it is closer to the file system, still the library implementation and the optimisations done would affect the runtime significantly and if that is the case we will end up comparing the implementation rather than the file format. 

Also another thing to note is that, the way you use the file format or the library can drastically affect performance. I being the designer of the S/BLOW5 format I know the best way to exploit its propoerties for the best performance for a given applictaion. I might be using the POD5 format in the wrong way, the POD5 designers can correct me if I am doing the wrong way.

Another thing to note is that doing a perfect disk I/O benchmark is very tricky due to the effects of different levels of disk caches, other programmes running in the back ground etc. I have tried to do the benchmarks with equal conditions as much as possible, but still it is not perfect. For instance, I clean the Linux O/S disk cache before each experiment, however, I cannot clean the hardware cache in the RAID controller if any.


Two key benchmarks are explored that represents two realistic workloads:

1. Accessing all the signal data and associated parameters required for pico-ampere conversion. This mimicks a typical basecalling workflow. We load a batch of reads from the disk, decompress and parse them into memory arrays; do the processing (in this case I just convert the raw signal to picoampere and sum them up); and, output the sum. Only the time for loading a batch of reads from the disk, decompressing and parsing them into memory arrays is measured.

The benchmark code for SLOW5 is available in the [slow5lib repository](https://github.com/hasindu2008/slow5lib/blob/dev/test/bench/convert_to_pa.c). See the comments for more information about compiling, implementation and caveats.

The benchmark code for POD5 is available [in this reposity](https://github.com/hasindu2008/slow5-pod5-bench/blob/master/pod5_convert_to_pa.c). See the comments for more information about compiling, implementation and caveats.


2. <todo> Random access in Nanopolish style

  
Note that POD5 format uses a newer version of vbz (16-bit encoding with SIMD acceleration). The closest available in BLOW5 is the previous version of vbz (32-bit encoding with no SIMD acceleration). I will implement this new vbz into slow5lib when it is stable and time permits and I expect this to further improve the BLOW5 file size and access performance.
  

