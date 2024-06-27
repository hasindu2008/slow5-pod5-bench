# slow5 bench

For equivalent conditions with vbz in POD5, must use svb16 in BLOW5. Also, make sure all compiler versions, optimisation flags and zstd versions are equivalent as explained in [here](../docs/conditions.md)

1. Prepare the input for the benchmark

  ```
  git clone --recursive https://github.com/hasindu2008/slow5tools -b vbz
  cd slow5tools
  make disable_hdf5=1 zstd=1 -j
  ./slow5tools view -c zstd -s svb16-zd PGXX22394_reads_1000.blow5 -o zstd-sv16-zd.blow5
  ```

  Double check if they are correct:
  ```
  ./slow5tools stats zstd-sv16-zd.blow5
  ```

  `record compression method` must be  `zstd` and `signal compression method` must be `svb16-zd`.

  For random benchmark, we must generate a read ID list. We can generate a random read ID list as:
  ```
  slow5tools skim --rid zstd-sv16-zd.blow5 | sort -R > ridlist.txt
  ```
  If you have a sorted BAM file,  you can create a list of read id based on sorted genomic coordinate order as:
  ```
  samtools view reads.sorted.bam | awk '{print $1}' > ridlist.txt
  ```


2. Compile the c benchmarks using `./build.sh`. Compile the cxx threadpool-based benchmark using `./build_cxxpool.sh`


3. Run the benchmarks

  i. sequential benchmark (c) can be run as:
  ```
  ./run_seq.sh zstd-sv16-zd.blow5 <num-threads> <batch_size> c
  ```

  ii. random benchmark (c) can be run as:
  ```
  # make sure a SLOW5 index exist before running this
  slow5_random zstd-sv16-zd.blow5 ridlist.txt <num-threads> <batch_size>
  ```

  iii. sequential benchmark (cxx) can be run as:
  ```
  ./run_seq.sh zstd-sv16-zd.blow5 <num-threads> <batch_size> cxx
  ```

---

An automatic benchmark script that does all the above is described under [autobench](autobench).

