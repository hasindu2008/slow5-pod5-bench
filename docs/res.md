# Results

### Experiment setup

### Dataset

- [HG002 PromethION 20X](https://gentechgp.github.io/gtgseq/docs/data.html#na24385-hg002-promethion-data-20x)
- 500k subsample of the above

### System information

- gtgpu-ssd: 20-core (40-threads) Intel(R) Xeon(R) Silver 4114 CPU, 377 GB of RAM, Ubuntu 18.04.5 LTS, local NVME SSD storage
- gtgpu-nfs: same above server with  network file system mounted over NFS (A synology NAS with traditional spinning disks with RAID)
- xavierjet2: ARM64 Linux 8 core
- macmini: M1 8 core


### Software versions used

- slow5lib bench branch commit 9ebde8f
- pod5 library 0.3.2


### Conversion:
```
/home/hasindu/hasindu2008.git/slow5tools-svb16/slow5tools view -c zstd -s svb16-zd PGXXXX230339_reads.blow5 -o PGXXXX230339_reads_zstd-sv16-zd.blow5 -t 16
/home/hasindu/hasindu2008.git/slow5tools-svb16/slow5tools index PGXXXX230339_reads_zstd-sv16-zd.blow5
blue-crab s2p PGXXXX230339_reads.blow5 -o PGXXXX230339_reads.pod5
```

### Sequential I/O benchmark

#### gtgpu-ssd (20 threads, 1000 batchsize, 20X dataset)

```
cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5
./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 c &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_c_1.log
./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 cxx &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_cxx_1.log
rm /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 /data/tmp/PGXXXX230339_reads.pod5
./run_seq.sh /data/tmp/PGXXXX230339_reads.pod5 20 &> gtgpu-ssd_PGXXXX230339_reads_20_1000_cxx_1.log
rm /data/tmp/PGXXXX230339_reads.pod5
```

BLOW C:

```
Time for disc reading 756.184760
Time for getting samples (disc+depress+parse) 985.309312
        Command being timed: "taskset -a -c 0-19 ./slow5_sequential /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 20 1000"
        User time (seconds): 10302.49
        System time (seconds): 329.99
        Percent of CPU this job got: 991%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 17:52.04
        Maximum resident set size (kbytes): 1938568
```
BLOW CXX:
```
Time for disc reading 784.479476
Time for getting samples (disc+depress+parse) 1014.710912
real time = 1191.439 sec | CPU time = 11450.553 sec | peak RAM = 1.499 GB
        Command being timed: "taskset -a -c 0-19 ./slow5_sequential_cxxpool /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 20 1000"
        User time (seconds): 10896.49
        System time (seconds): 554.14
        Percent of CPU this job got: 960%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 19:51.53
        Maximum resident set size (kbytes): 1571684
```

POD5 CXX:




#### gtgpu-nfs (20 threads, 1000 batchsize, 20X dataset)

```
cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 c &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_c_1.log
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 cxx &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_cxx_1.log

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/


```

#### xavierjet (8 threads, 1000 batchsize, 20X dataset)

```
cd /data/hasindu/slow5-pod5-bench/slow5
./run_seq.sh ../data/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 c &> xavierjet2_PGXXXX230339_reads_zstd-sv16-zd_8_1000_c_1.log
./run_seq.sh ../data/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 cxx &> xavierjet2_PGXXXX230339_reads_zstd-sv16-zd_8_1000_cxx_1.log


cd /data/hasindu/slow5-pod5-bench/pod5
./run_seq.sh ../data/PGXXXX230339_reads.pod5 8 &> xavierjet2_PGXXXX230339_reads_8_1000_cxx_1.log

```

BLOW5 C:
```
Time for disc reading 749.030690
Time for getting samples (disc+depress+parse) 1387.992781
    User time (seconds): 4020.51
    System time (seconds): 622.37
    Percent of CPU this job got: 306%
    Elapsed (wall clock) time (h:mm:ss or m:ss): 25:16.18
    Maximum resident set size (kbytes): 1469796
```
BLOW5 CXX:
```
Time for disc reading 775.145377
Time for getting samples (disc+depress+parse) 1304.644667
real time = 1460.266 sec | CPU time = 4935.438 sec | peak RAM = 1.140 GB
        Command being timed: "taskset -a -c 0-7 ./slow5_sequential_cxxpool ../data/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000"
        User time (seconds): 4199.61
        System time (seconds): 735.86
        Percent of CPU this job got: 337%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 24:20.34
        Maximum resident set size (kbytes): 1195560
```

POD5 CXX:
```
Time for getting samples (disc+depress+parse) 1550.907379
real time = 1743.637 sec | CPU time = 8818.569 sec | peak RAM = 13.696 GB
        Command being timed: "taskset -a -c 0-7 ./pod5_sequential ../data/PGXXXX230339_reads.pod5 8"
        User time (seconds): 5690.20
        System time (seconds): 3128.46
        Percent of CPU this job got: 505%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:03.79
        Maximum resident set size (kbytes): 14361208
```
#### macmini (8 threads, 1000 batchsize, 500K dataset)

Note: slow5 compiled with g++-12, no clean_fscache or taskset

```
cd /Users/gtg/slow5-pod5-bench/slow5
./slow5_sequential_cxxpool ../data/PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 8 1000 > /dev/null

cd /Users/gtg/slow5-pod5-bench/pod5
#ln /Users/gtg/slow5-pod5-bench/pod5/pod5_format/lib/libpod5_format.dylib libpod5_format.dylib
./pod5_sequential ../data/PGXXXX230339_reads_500k.pod5 8 > /dev/null
```

BLOW5 CXX:
```
    Time for disc reading 7.625196
    Time for getting samples (disc+depress+parse) 19.595953
```
POD5 CXX:
```
    Time for getting samples (disc+depress+parse) 34.798733
```

### minifridge (16 threads, 1000 batchsize, 20X dataset)

```
scp gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data2/tmp/
./run_seq.sh /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 16 1000 c &>  minifridge_PGXXXX230339_reads_zstd-sv16-zd_8_1000_c_1.log


rm /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5


```

### fridge:

```
./run_seq.sh /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 32 1000 c &>  fridge_PGXXXX230339_reads_zstd-sv16-zd_32_1000_c_1.log

```

### Random I/O benchmark