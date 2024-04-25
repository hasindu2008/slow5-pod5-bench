# Experiment Conditions

## Access patterns to test

1. sequential [basecall/methcall]
2. random [duplex/f5c/squigualiser]

The fields accessed (in order) are [here](https://github.com/nanoporetech/dorado/blob/0d932c0539a8d81fedb5c98931475e69dd97df93/dorado/data_loader/DataLoader.cpp#L112)
1. run_acquisition_start_time_ms
2. sample_rate
3. read_id
4. num_samples
5. raw_signal
6. start_sample
7. calibration_scale (scaling)
8. calibration_offset (offset)
9. read_number
10. well (mux)
11. channel (channel number)
12. acquisition_id (run_id)
13. flowcell_id
14. sequencer_position (position_id)
15. experiment_name (experiment_id)

## Disks

1. SSD [brenner nvme]
2. HDD [nci lustre]

## Dataset

Full prom 5KHz: available via
- gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz_2/PGXXSX240041_reads.blow5

## systems

1. Server
2. Embedded system - Jetson Xavier
3. Mac Mini?
4. tablet/mobile phone/ipad?

## Match conditions

1. What are the compiler versions used in pod5?

```
objdump -s --section .comment lib/libpod5_format.so 

lib/libpod5_format.so:     file format elf64-x86-64

Contents of section .comment:
 0000 4743433a 2028474e 55292031 302e322e  GCC: (GNU) 10.2.
 0010 31203230 32313031 33302028 52656420  1 20210130 (Red 
 0020 48617420 31302e32 2e312d31 31290047  Hat 10.2.1-11).G
 0030 43433a20 28474e55 2920392e 332e3120  CC: (GNU) 9.3.1 
 0040 32303230 30343038 20285265 64204861  20200408 (Red Ha
 0050 7420392e 332e312d 32290047 43433a20  t 9.3.1-2).GCC: 
 0060 28474e55 2920342e 382e3520 32303135  (GNU) 4.8.5 2015
 0070 30363233 20285265 64204861 7420342e  0623 (Red Hat 4.
 0080 382e352d 34342900                    8.5-44).        
```

3. What are the compiler flags used in pod5? 
4. What is the zstd version used in pod5? [zstd/1.5.4](https://github.com/nanoporetech/pod5-file-format/blob/0ba232d6304dd1eebd60d331a6f7c15099dcd04f/conanfile.py#L60)

Make sure:
- access same fields in same order
- match compiler versions and flags
- compression method should match (svb12+zigzag+zstd) 
- SIMD accelerated version of svb in slow5lib
- zstd version should match
- POD5 must use streaming I/O (opposed to memory mapping)
- POD5 must use default chunk size as in MinKNOW, as it was the reason why ONT could not integrate SLOW5 to their minKNOW
- GLIBC and other system library versions must match
- use taskset command to force using N number of CPUs
- clean_fscache to prevent caching
- **note** : use jemalloc https://github.com/nanoporetech/pod5-file-format/blob/6b8bbc7bd6e51e878a933cef32fc94a9cb30443a/conanfile.py#L69C28-L69C36

# Checklist

POD5 version: 0.3.10

| Conditions                         | pod5 IO stream             | pod5 mmap        | blow5 IO stream        | blow5 mmap             |
| ---------------------------------- | -------------------------- | ---------------- | ---------------------- | ---------------------- |
| File compression/version           | File v0.3.2, read table v3 | File v0.3.2, read table v3                 | zstd-sv16-zd           |  zstd-sv16-zd          |
| Disk                               | SSD                        | SSD              | SSD                    | SSD                    |
| Benchmark program compiler version | g++ 7.5.0                  | g++ 7.5.0        | gcc 7.5.0              | gcc 7.5.0              |
| Bencmark program compiler flags    | g++ -Wall -O3 -g           | g++ -Wall -O3 -g | gcc -Wall -O3 -g       | gcc -Wall -O3 -g       |
| Library compiler version           | gcc 10.2                 | gcc 10.2        | gcc 7.5.0              | gcc 7.5.0              |
| Libarry compiler flags             | \-g -Wall -O3              | \-g -Wall -O3    | \-g -Wall -O3 -std=c99 | \-g -Wall -O3 -std=c99 |
| Taskset                            | used                       | used             | used                   | used                   |
| streamvbyte                        | N/A               | N/A     | \-g -Wall -O3          | \-g -Wall -O3          |
| zstd version                       | 1.5.4                      | 1.5.4            | 1.5.4                  | 1.5.4                        |  
| POD5_DISABLE_MMAP_OPEN             | set                        | not set          | N/A                    | N/A                    |


# Misc

See if using traditional I/O instead of mmap
```
unset POD5_DISABLE_MMAP_OPEN
strace -c -f -w ./pod5/build/pod5_sequential /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.pod5 1

export POD5_DISABLE_MMAP_OPEN=1 
strace -c -f -w ./pod5/build/pod5_sequential  /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.pod5 1
```

See the perf profile to see if SIMD is used
```
perf record slow5/slow5_sequential /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k_zstd-svb16-zd.blow5 1 1000
perf report -n
vtune -collect hotspots   slow5/slow5_sequential /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k_zstd-svb16-zd.blow5 1 1000
```

LIMIT ARROW THREADS
Using the environment variables described [here](https://arrow.apache.org/docs/cpp/env_vars.html#environment-variables)
1. [ARROW_IO_THREADS](https://arrow.apache.org/docs/cpp/env_vars.html#envvar-ARROW_IO_THREADS)
2. [OMP_NUM_THREADS](https://arrow.apache.org/docs/cpp/env_vars.html#envvar-OMP_NUM_THREADS)
3. [OMP_THREAD_LIMIT](https://arrow.apache.org/docs/cpp/env_vars.html#envvar-OMP_THREAD_LIMIT)

# Quick benchmark single threaded

```
export POD5_DISABLE_MMAP_OPEN=1
taskset -c 8 /usr/bin/time -v  ./pod5/pod5_convert_to_pa /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k.pod5 1 > a.txt

taskset -c 8 /usr/bin/time -v  slow5/slow5_sequential /data/slow5-testdata/hg2_prom_lsk114_5khz_subsubsample/PGXXXX230339_reads_20k_zstd-svb16-zd.blow5 1 1000 > b.txt
```

BLOW5 with zstd 1.3.1, 32-bit non-simd svb-zd, gcc optimisation level 2: 
```
Time for disc reading 0.349551
Time for getting samples (disc+depress+parse) 5.258698
```
BLOW5 with zstd 1.5.4, 32-bit non-simd svb-zd, gcc optimisation level 3: 
```
Time for disc reading 0.338519
Time for getting samples (disc+depress+parse) 3.695059
```
BLOW5 with zstd 1.5.4, 16-bit simd svb-zd, gcc optimisation level 3: 
```
Time for disc reading 0.310750
Time for getting samples (disc+depress+parse) 2.631733
```


