# slow5-pod5-bench

In this repository, we provide the source code for benchmarking the S/BLOW5 format vs POD5 format using the C/C++ API. The associated publication:

Preprint: https://doi.org/10.1101/2025.06.30.662478

paper: https://doi.org/10.1093/gigascience/giaf118

> Hasindu Gamaarachchi, Sasha Jenner, Hiruna Samarakoon, James M Ferguson, Ira W Deveson, The enduring advantages of the SLOW5 file format for raw nanopore sequencing data, GigaScience, Volume 14, 2025, giaf118, https://doi.org/10.1093/gigascience/giaf118

```
@article{gamaarachchi2025enduring,
  title={The enduring advantages of the SLOW5 file format for raw nanopore sequencing data},
  author={Gamaarachchi, Hasindu and Jenner, Sasha and Samarakoon, Hiruna and Ferguson, James M and Deveson, Ira W},
  journal={GigaScience},
  volume={14},
  pages={giaf118},
  year={2025},
  publisher={Oxford University Press}
}
```

## Cloning the respository

First, clone this repository and enter the repository as follows:
```bash
git clone --recursive https://github.com/hasindu2008/slow5-pod5-bench
cd slow5-pod5-bench
```

## Preparing the inputs

### Prepare the input BLOW5 for the benchmark.

For equivalent conditions with vbz compression in POD5, make sure to use the same compression in BLOW5.
Data in POD5 can be converted to BLOW5 using [blue-crab](https://github.com/Psy-Fer/blue-crab). Assume this creates a file called `reads.blow5` that uses the default compression.
Now to convert this to a BLOW5 file with vbz compression necessary inputs for the benchmarks using a BLOW5 file called `reads.blow5`. 

```
git clone --recursive https://github.com/hasindu2008/slow5tools -b vbz
cd slow5tools
make disable_hdf5=1 zstd=1 -j
./slow5tools view -c zstd -s svb16-zd PGXX22394_reads_1000.blow5 -o zstd-sv16-zd.blow5
./slow5tools index zstd-sv16-zd.blow5
```

Double-check if the compression is correct:
```
./slow5tools stats zstd-sv16-zd.blow5
```

`record compression method` must be  `zstd` and `signal compression method` must be `svb16-zd`.

### Read ID list for random access

For the random access benchmark, we must generate a read ID list. The same list has to be used for both BLOW5 and POD5. We can generate a random read ID list called `ridlist.txt` as:
 ```
 slow5tools skim --rid zstd-sv16-zd.blow5 | sort -R > ridlist.txt
 ```
 If you have a sorted BAM file,  you can create a list of read IDs based on the sorted genomic coordinate order as:
 ```
 samtools view reads.sorted.bam | awk '{print $1}' > ridlist.txt
 ```

## slow5 benchmark

The benchmark code for SLOW5 is available in the [slow5 subdirectory](slow5/README.md). We must make sure all compiler versions, optimisation flags and zstd versions are equivalent to those used in POD5. 

1. Enter the slow5/ directory
   ```bash
   cd slow5/
   ```

2. Compile the C++ benchmark programs:
   ```bash
   ./build_cxxpool.sh
   ```

3. Run the sequential access benchmark:
   ```bash
   ./run_seq.sh zstd-sv16-zd.blow5 <num-threads> 1000 cxx
   ```
   
4. Run the random access benchmark:
   ```bash
   ./run_rand.sh zstd-sv16-zd.blow5 ridlist.txt <num-threads> 1000 cxx
   ```


## pod5 benchmark

The benchmark code for POD5 is available in the [pod5 subdirectory](pod5/README.md).

1. Enter the pod5/ directory
   ```
   cd pod5/
   ```
   
2.  Download prebuilt pod5 library binaries
    ```bash
    wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
    tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
    export LD_LIBRARY_PATH=$PWD/pod5_format/lib
    ```

3. Compile the benchmark programs:
   ```bash
   ./build.sh
   ```

4. Run the sequential access benchmark:
   ```bash
   ./run_seq.sh reads.pod5 <num-threads> mmap
   ```

5. Run the random access benchmark
   ```bash
   ./run_rand.sh reads.pod5 ridlist.txt <num-threads> 1000 mmap 
   ```

## Notes

- Refer to the preprint and the associated supplementary notes for more details
- The source code, including scripts in this repository, is under the MIT license. Any test data (e.g., test blow5 files) in the repository are under the CC0 public waiver.
- This repository is only for benchmarking reading. There is no example code or documentation from ONT on how to use pod5 C++ API for writing. We have [requested ONT for this](https://github.com/nanoporetech/pod5-file-format/issues/167), but no response yet as of 12.09.2025.

## See also

- [pyslow5-pod5-writer-benchmark](https://github.com/Psy-Fer/pyslow5-pod5-writer-benchmark): Python-based writing benchmark
- [slowION](https://github.com/hasindu2008/slowion): for a slow5-based writing simulator
- [slow5 ecosystem](https://hasindu2008.github.io/slow5)



