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