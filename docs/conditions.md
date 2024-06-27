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

## Datasets

Full prom 5KHz: available via
- [PGXXXX230339_reads.blow5](https://gtgseq.s3.amazonaws.com/ont-r10-5khz-dna/NA24385/raw/PGXXXX230339_reads.blow5)
- [PGXXSX240041_reads.blow5](https://gtgseq.s3.amazonaws.com/ont-r10-5khz-dna/NA24385_2/raw/PGXXSX240041_reads.blow5)

## systems

1. Server
2. Embedded system - Jetson Xavier
3. Mac Mini?
4. tablet/mobile phone/ipad?

## Checking conditions

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

4. What is the zstd version used in pod5? [zstd/1.5.5](https://github.com/nanoporetech/pod5-file-format/blob/0.3.10/conanfile.py#L63)

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
- **note** : use [jemalloc  5.2.1](https://github.com/nanoporetech/pod5-file-format/blob/0.3.10/conanfile.py#L70)

# Match conditions Checklist

POD5 version: 0.3.10

| Conditions                         | pod5 IO stream             | pod5 mmap        | blow5 IO stream        | blow5 mmap             |
| ---------------------------------- | -------------------------- | ---------------- | ---------------------- | ---------------------- |
| File compression/version           | File v0.3.2, read table v3 | File v0.3.2, read table v3                 | zstd-sv16-zd           |  zstd-sv16-zd          |
| Disk                               | SSD                        | SSD              | SSD                    | SSD                    |
| Benchmark program compiler version | g++ 10                 | g++ 10        | gcc 10              | gcc 10              |
| Bencmark program compiler flags    | g++ -Wall -O3 -g           | g++ -Wall -O3 -g | gcc -Wall -O3 -g       | gcc -Wall -O3 -g       |
| Library compiler version           | gcc 10                 | gcc 10        | gcc 10               | gcc 10 0              |
| Libarry compiler flags             | \-g -Wall -O3              | \-g -Wall -O3    | \-g -Wall -O3 -std=c99 | \-g -Wall -O3 -std=c99 |
| Taskset                            | used                       | used             | used                   | used                   |
| streamvbyte                        | N/A               | N/A     | \-g -Wall -O3          | \-g -Wall -O3          |
| zstd version                       | 1.5.5                      | 1.5.5            | 1.5.5                  | 1.5.5                        |
| POD5_DISABLE_MMAP_OPEN             | set                        | not set          | N/A                    | N/A                    |



