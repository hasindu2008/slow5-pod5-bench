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
- https://gtgseq.s3.amazonaws.com/index.html#ont-r10-5khz-dna/NA24385/raw/
- gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.blow5

## systems

1. Server
2. Embedded system

## Match conditions

1. What are the compiler versions used in pod5? TODO
2. What are the compiler flags used in pod5? TODO
3. What is the zstd version used in pod5? [zstd/1.5.4](https://github.com/nanoporetech/pod5-file-format/blob/0ba232d6304dd1eebd60d331a6f7c15099dcd04f/conanfile.py#L60)

Make sure:

- SIMD accelerated version of svb in slow5lib
- POD5 must use streaming I/O (opposed to memory mapping)
- POD5 must use default chunk size as in MinKNOW, as it was the reason why ONT could not integrate SLOW5 to their minKNOW

- use taskset command to force using N number of CPUs
- clean_fscache to prevent caching
- **note** : use jemalloc https://github.com/nanoporetech/pod5-file-format/blob/6b8bbc7bd6e51e878a933cef32fc94a9cb30443a/conanfile.py#L69C28-L69C36

# Checklist

| Conditions                         | pod5 IO stream             | pod5 mmap        | blow5 IO stream        | blow5 mmap             |
| ---------------------------------- | -------------------------- | ---------------- | ---------------------- | ---------------------- |
| File compression/version           | File v0.3.2, read table v3 | File v0.3.2, read table v3                 | zstd-sv16-zd           |  zstd-sv16-zd          |
| Disk                               | SSD                        | SSD              | SSD                    | SSD                    |
| Benchmark program compiler version | g++ 7.5.0                  | g++ 7.5.0        | gcc 7.5.0              | gcc 7.5.0              |
| Bencmark program compiler flags    | g++ -Wall -O2 -g           | g++ -Wall -O2 -g | gcc -Wall -O2 -g       | gcc -Wall -O2 -g       |
| Library compiler version           | not known                  | not known        | gcc 7.5.0              | gcc 7.5.0              |
| Libarry compiler flags             | \-g -Wall -O3              | \-g -Wall -O3    | \-g -Wall -O3 -std=c99 | \-g -Wall -O2 -std=c99 |
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


