# Experiment Conditions

## Access patterns to test

1. sequential [basecall/methcall]
2. random [duplex/f5c/squigualiser]

The fields accessed (in order) are
1. run_acquisition_start_time_ms
2. run_sample_rate
3. read_id
4. num_samples
5. raw_signal
6. start_sample
7. scaling
8. offset
9. read_number
10. well
11. channel
12. acquisition_id (run_id)
13. flow_cell_id

## Disks 

1. SSD [brenner nvme]
2. HDD [nci lustre]

## Dataset

Full prom 5KHz: available via
- https://gtgseq.s3.amazonaws.com/index.html#ont-r10-5khz-dna/NA24385/raw/
- gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.blow5

## Match conditions

1. What are the compiler versions used in pod5?
2. What are the compiler flags used in pod5?
3. What is the zstd version used in pod5?

- SIMD accelerated version of svb in slow5lib
- POD5 must use streaming I/O (opposed to memory mapping)
- POD5 must use default chunk size as in MinKNOW, as it was the reason why ONT could not integrate SLOW5 to their minKNOW

