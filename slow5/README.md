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

```
On gadi first do:
ln -s /apps/gcc/10.3.0/bin/gcc ~/.local/bin/gcc-10
ln -s /apps/gcc/10.3.0/bin/g++ ~/.local/bin/g++-10

On Pawsey:
ln -s /opt/cray/pe/gcc/10.3.0/snos/bin/gcc ~/.local/bin/gcc-10
ln -s /opt/cray/pe/gcc/10.3.0/snos/bin/g++ ~/.local/bin/g++-10
on glab:
ln -s /share/apps/z_install_tree/linux-debian12-zen3/gcc-12.2.0/gcc-10.5.0-f5ilsjdd3ra637qfxkkeg7m375xbqrsb/bin/gcc ~/.local/bin/gcc-10
ln -s /share/apps/z_install_tree/linux-debian12-zen3/gcc-12.2.0/gcc-10.5.0-f5ilsjdd3ra637qfxkkeg7m375xbqrsb/bin/g++ ~/.local/bin/g++-10
```

3. Run the benchmarks

on Gadi first:
```
ln -s /g/data/ox63/install/clean_fscache/clean_fscache ~/.local/bin/clean_fscache
```

  i. sequential benchmark (c) can be run as:
  ```
  ./run_seq.sh zstd-sv16-zd.blow5 <num-threads> <batch_size> c
  ```

  ii. random benchmark (c) can be run as:
  ```
  # make sure a SLOW5 index exist before running this
  ./run_rand.sh zstd-sv16-zd.blow5 ridlist.txt <num-threads> <batch_size> c
  ```

  iii. sequential benchmark (cxx) can be run as:
  ```
  ./run_seq.sh zstd-sv16-zd.blow5 <num-threads> <batch_size> cxx
  ```

  iv. random benchmark (cxx) can be run as:
  ```
  # make sure a SLOW5 index exist before running this
  ./run_rand.sh zstd-sv16-zd.blow5 ridlist.txt <num-threads> <batch_size> cxx
  ```

---

An automatic benchmark script that does all the above is described under [autobench](autobench).

