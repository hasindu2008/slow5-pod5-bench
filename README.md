# slow5-pod5-bench

**UPDATE**

In this repository, we benchmark the S/BLOW5 format vs POD5 format using the C API (actually C++). C is close to the file system than high-level languages like Python and therefore in my opinion it is a better choice to benchmark a file format. When using high level languages like Python, data type conversion that happens under the hood can dominate the execution time, thus would not be respresetative of the file format performance. However, despite being close to  the file system, even in the C API, this will be the case to a certain degree. That is, the library implementation and optimisations done would affect the runtime considerablu and if that is the case we will end up comparing the implementation rather than the file format. See caveats below before interpreting the results.


## Benchmark details

**UPDATE**
Accessing all the signal data and associated parameters required for pico-ampere conversion. This mimicks a typical basecalling workflow. We load a batch of reads from the disk, decompress and parse them into memory arrays; do the processing (in this case I just convert the raw signal to picoampere and sum them up); and, output the sum. Only the time for loading a batch of reads from the disk, decompressing and parsing them into memory arrays is measured.



 ## Results

**UPDATE**

 ### NA12878 subsample (500,000 reads)

Conversion (done on server with SSD using 40 threads/processes):
```
 slow5tools f2s:      98.208s
 slow5tools cat:      52.703s
 pod5-convert-fast5:  137.51s

 merged_zstd.blow5 37G
 pod5/output.pod5 37G
  ```

### Benchmark 1

On server with SSD using:
```
BLOW5:  55.969939 s
POD5:   151.387814
```

On server with NAS:
```
BLOW5: 89.589880
POD5:  254.235119
```

### NA12878 prom (9.1M reads)

On server with NAS:
```
BLOW5: 1839.534667s # 1321.919755s for disk operations, rest for decompression and parsing
POD5:  4933.334736s
```

## Experiment setup

### Datasets

**UPDATE**
Two datasets are used:
1. NA12878 subset contains 500,000 reads. Download the [subset of Nanopore WGS of NA12878 from SRA](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=744329).
2. NA12878 promethION sample containing 9.1M reads. Download the [Nanopore WGS of NA12878 - raw signal data from SRA](https://www.ncbi.nlm.nih.gov/sra?linkname=bioproject_sra_all&from_uid=744329).


### System information

**UPDATE**
Server with SSD: 20-core (40-threads) Intel(R) Xeon(R) Silver 4114 CPU, 377 GB of RAM, Ubuntu 18.04.5 LTS, local NVME SSD storage
Server with NFS: same above server with  network file system mounted over NFS (A synology NAS with traditional spinning disks with RAID)



### Software versions used

slow5lib dev branch
pod5 library vxxxx


### Code (outdated)

The benchmark code for SLOW5 is available in the [slow5 subdirectory](slow5/README.md)

The benchmark code for POD5 is available in the [pod5 subdirectory](pod5/README.md)


 ## Caveats


- Furthermore, doing a perfect disk I/O benchmark is very tricky due to the effects of different levels of disk caches, other programmes running in the background, etc. I have tried to do the benchmarks with equal conditions as much as possible, but still it is not perfect. For instance, I clean the Linux O/S disk cache before each experiment, however, I cannot clean the hardware cache in the RAID controller, if any.


