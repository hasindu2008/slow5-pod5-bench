# Results

## Table of Contents

- [Experiment Setup](#experiment-setup)
- [Dataset](#dataset)
  - [HG002 PromethION 20X](https://gentechgp.github.io/gtgseq/docs/data.html#na24385-hg002-promethion-data-20x)
- [System Information](#system-information)
- [Software Versions Used](#software-versions-used)
- [Conversion](#conversion)
- [Sequential I/O Benchmark](#sequential-io-benchmark)
  - [gtgpu-ssd (20 threads, 1000 batchsize, 20X dataset)](#gtgpu-ssd-20-threads-1000-batchsize-20x-dataset)
  - [gtgpu-nfs (20 threads, 1000 batchsize, 20X dataset)](#gtgpu-nfs-20-threads-1000-batchsize-20x-dataset)
  - [xavierjet (8 threads, 1000 batchsize, 20X dataset)](#xavierjet-8-threads-1000-batchsize-20x-dataset)
  - [macmini (8 threads, 1000 batchsize, 500K dataset)](#macmini-8-threads-1000-batchsize-500k-dataset)
  - [minifridge (8 threads, 1000 batchsize, 20X dataset)](#minifridge-8-threads-1000-batchsize-20x-dataset)
  - [fridge-ssd (32 threads, 1000 batch size, 20X)](#fridge-ssd-32-threads-1000-batch-size-20x)
  - [fridge-nvme (32 threads, 1000 batch size, 20X)](#fridge-nvme-32-threads-1000-batch-size-20x)
  - [extra](#extra)
- [Random I/O Benchmark](#random-io-benchmark)


## Experiment setup

## Dataset

- [HG002 PromethION 20X](https://gentechgp.github.io/gtgseq/docs/data.html#na24385-hg002-promethion-data-20x)
- 500k subsample of the above

## System information

- gtgpu-ssd: 20-core (40-threads) Intel(R) Xeon(R) Silver 4114 CPU, 377 GB of RAM, Ubuntu 18.04.5 LTS, local NVME SSD storage
- gtgpu-nfs: same above server with  network file system mounted over NFS (A synology NAS with traditional spinning disks with RAID)
- xavierjet2: ARM64 Linux 8 core
- macmini: M1 8 core
- minifridge
- fridge-ssd
- fridge-nvme
- gadi?


## Software versions used

- slow5lib bench branch commit 9ebde8f
- pod5 library 0.3.2


## Conversion
```
/home/hasindu/hasindu2008.git/slow5tools-svb16/slow5tools view -c zstd -s svb16-zd PGXXXX230339_reads.blow5 -o PGXXXX230339_reads_zstd-sv16-zd.blow5 -t 16
/home/hasindu/hasindu2008.git/slow5tools-svb16/slow5tools index PGXXXX230339_reads_zstd-sv16-zd.blow5
blue-crab s2p PGXXXX230339_reads.blow5 -o PGXXXX230339_reads.pod5
```

PGXXXX230339_reads_zstd-sv16-zd.blow5: 740G

## Sequential I/O benchmark

### gtgpu-ssd (20 threads, 1000 batchsize, 20X dataset)


```
sudo  smartctl -i /dev/nvme0n1
fio --name=fiotest --filename=/data/tmp/tmp  --size=16Gb --rw=read --bs=1M --direct=1 --numjobs=8 --ioengine=libaio --iodepth=8 --group_reporting

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5
./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 c &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_c_1.log
./run_seq.sh /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 cxx &> gtgpu-ssd_PGXXXX230339_reads_zstd-sv16-zd_20_1000_cxx_1.log
rm /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 /data/tmp/PGXXXX230339_reads.pod5
./run_seq.sh /data/tmp/PGXXXX230339_reads.pod5 20 io &> gtgpu-ssd_PGXXXX230339_reads_20_io_cxx_1.log
./run_seq.sh /data/tmp/PGXXXX230339_reads.pod5 20 mmap &> gtgpu-ssd_PGXXXX230339_reads_20_mmap_cxx_1.log
rm /data/tmp/PGXXXX230339_reads.pod5
```

#### theoritical
```
Dell Express Flash PM1725b 6.4TB AIC: 6GB/s
READ: bw=5638MiB/s (5911MB/s), 5638MiB/s-5638MiB/s (5911MB/s-5911MB/s), io=128GiB (137GB), run=23250-23250msec
```

#### BLOW C
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

#### BLOW CXX
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

#### POD5 CXX IO
```
Time for getting samples (disc+depress+parse) 1193.171438
real time = 1415.727 sec | CPU time = 11763.283 sec | peak RAM = 1.380 GB
        Command being timed: "taskset -a -c 0-19 ./pod5_sequential /data/tmp/PGXXXX230339_reads.pod5 20"
        User time (seconds): 11109.10
        System time (seconds): 654.28
        Percent of CPU this job got: 830%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 23:35.83
        Maximum resident set size (kbytes): 1446856
```

#### POD5 CXX MMAP
```
Time for getting samples (disc+depress+parse) 594.012754
real time = 829.947 sec | CPU time = 13382.208 sec | peak RAM = 363.683 GB
        Command being timed: "taskset -a -c 0-19 ./pod5_sequential /data/tmp/PGXXXX230339_reads.pod5 20"
        User time (seconds): 11386.80
        System time (seconds): 1995.45
        Percent of CPU this job got: 1612%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 13:50.04
        Maximum resident set size (kbytes): 381349656
```

### gtgpu-nfs (20 threads, 1000 batchsize, 20X dataset)

```
fio --name=fiotest --filename=/home/hasindu/scratch/tmp/tmp  --size=16Gb --rw=read --bs=1M --direct=1 --numjobs=8 --ioengine=libaio --iodepth=8 --group_reporting

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/slow5
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 c &> gtgpu-nfs_PGXXXX230339_reads_zstd-sv16-zd_20_1000_c_1.log
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5  20 1000 cxx &> gtgpu-nfs_PGXXXX230339_reads_zstd-sv16-zd_20_1000_cxx_1.log

cd /data/hasindu/hasindu2008.git/slow5-pod5-bench/pod5
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 20 io &> gtgpu-nfs_PGXXXX230339_reads_20_io_cxx_1.log
./run_seq.sh /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 20 mmap &> gtgpu-nfs_PGXXXX230339_reads_20_mmap_cxx_1.log
```

#### Theoritical

```
 READ: bw=1042MiB/s (1092MB/s), 1042MiB/s-1042MiB/s (1092MB/s-1092MB/s), io=128GiB (137GB), run=125846-125846msec
```

#### BLOW5 C
```
Time for disc reading 1306.828444
Time for getting samples (disc+depress+parse) 1571.661276
real time = 1718.835 sec | CPU time = 12321.382 sec | peak RAM = 1.854 GB | CPU Usage = 35.8%
        Command being timed: "taskset -a -c 0-19 ./slow5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 20 1000"
        User time (seconds): 11878.35
        System time (seconds): 443.15
        Percent of CPU this job got: 716%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 28:38.91
        Maximum resident set size (kbytes): 1944220
```

#### BLOW5 CXX
```
Time for disc reading 1329.285290
Time for getting samples (disc+depress+parse) 1530.227079
real time = 1730.983 sec | CPU time = 11754.985 sec | peak RAM = 1.550 GB
        Command being timed: "taskset -a -c 0-19 ./slow5_sequential_cxxpool /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 20 1000"
        User time (seconds): 11166.90
        System time (seconds): 588.22
        Percent of CPU this job got: 679%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 28:51.09
        Maximum resident set size (kbytes): 1625264
```
#### POD5 CXX IO
```
Time for getting samples (disc+depress+parse) 1585.794381
real time = 1830.628 sec | CPU time = 12051.133 sec | peak RAM = 1.390 GB
        Command being timed: "taskset -a -c 0-19 ./pod5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 20"
        User time (seconds): 11301.80
        System time (seconds): 749.40
        Percent of CPU this job got: 658%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 30:30.75
        Maximum resident set size (kbytes): 1457624
```

#### POD5 CXX MMAP

```
Time for getting samples (disc+depress+parse) 2531.324096
real time = 2781.651 sec | CPU time = 17150.198 sec | peak RAM = 363.705 GB
        Command being timed: "taskset -a -c 0-19 ./pod5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 20"
        User time (seconds): 9706.45
        System time (seconds): 7443.80
        Percent of CPU this job got: 616%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 46:21.75
        Maximum resident set size (kbytes): 381372520
```


### xavierjet (8 threads, 1000 batchsize, 20X dataset)


```
fio --name=fiotest --filename=/data/fiotest  --size=16Gb --rw=read --bs=1M --direct=1 --numjob
s=8 --ioengine=libaio --iodepth=8 --group_reporting

cd /data/hasindu/slow5-pod5-bench/slow5
./run_seq.sh ../data/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 c &> xavierjet2_PGXXXX230339_reads_zstd-sv16-zd_8_1000_c_1.log
./run_seq.sh ../data/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 cxx &> xavierjet2_PGXXXX230339_reads_zstd-sv16-zd_8_1000_cxx_1.log

cd /data/hasindu/slow5-pod5-bench/pod5
./run_seq.sh ../data/PGXXXX230339_reads.pod5 8 io &> xavierjet2_PGXXXX230339_reads_8_io_cxx_1.log
./run_seq.sh ../data/PGXXXX230339_reads.pod5 8 mmap &> xavierjet2_PGXXXX230339_reads_8_mmap_cxx_1.log
```

#### Theoritical
```
Samsung SSD 970 EVO Plus 2TB: 3500MB/s
READ: bw=1935MiB/s (2029MB/s), 1935MiB/s-1935MiB/s (2029MB/s-2029MB/s), io=128GiB (137GB), run=67752-67752msec
```

#### BLOW5 C
```
Time for disc reading 749.030690
Time for getting samples (disc+depress+parse) 1387.992781
    User time (seconds): 4020.51
    System time (seconds): 622.37
    Percent of CPU this job got: 306%
    Elapsed (wall clock) time (h:mm:ss or m:ss): 25:16.18
    Maximum resident set size (kbytes): 1469796
```

#### BLOW5 CXX
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

#### POD5 CXX IO
```
Time for getting samples (disc+depress+parse) 1186.981775
real time = 1344.014 sec | CPU time = 5037.281 sec | peak RAM = 0.947 GB | CPU Usage = 46.8%
        Command being timed: "taskset -a -c 0-7 ./pod5_sequential ../data/PGXXXX230339_reads.pod5 8"
        User time (seconds): 4341.19
        System time (seconds): 696.12
        Percent of CPU this job got: 374%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 22:24.10
        Maximum resident set size (kbytes): 993204
```

#### POD5 CXX MMAP
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
### macmini (8 threads, 1000 batchsize, 500K dataset)

Note: slow5 compiled with g++-12, no clean_fscache or taskset

```
cd /Users/gtg/slow5-pod5-bench/slow5
./slow5_sequential_cxxpool ../data/PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 8 1000 > /dev/null

cd /Users/gtg/slow5-pod5-bench/pod5
#ln /Users/gtg/slow5-pod5-bench/pod5/pod5_format/lib/libpod5_format.dylib libpod5_format.dylib
./pod5_sequential ../data/PGXXXX230339_reads_500k.pod5 8 > /dev/null
```

#### BLOW5 CXX
```
    Time for disc reading 7.625196
    Time for getting samples (disc+depress+parse) 19.595953
```
#### POD5 CXX
```
    Time for getting samples (disc+depress+parse) 34.798733
```

### minifridge (8 threads, 1000 batchsize, 20X dataset)

```
sudo  hdparm -I /dev/sda | less
fio --name=fiotest --filename=/data2/tmp/fiotest  --size=16Gb --rw=read --bs=1M --direct=1 --numjobs=8 --ioengine=libaio --iodepth=8 --group_reporting

scp gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 /data2/tmp/
./run_seq.sh /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 c &>  minifridge_PGXXXX230339_reads_zstd-sv16-zd_8_1000_c_1.log
./run_seq.sh /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000 cxx &>  minifridge_PGXXXX230339_reads_zstd-sv16-zd_8_1000_cxx_1.log
rm /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5

scp gtgpu:/home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 /data2/tmp/
./run_seq.sh /data2/tmp/PGXXXX230339_reads.pod5 8 io &> minifridge_PGXXXX230339_reads_8_io_cxx_1.log
./run_seq.sh /data2/PGXXXX230339_reads.pod5 8 mmap &> minifridge_PGXXXX230339_reads_8_mmap_cxx_1.log
rm /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5
```

#### Theoritical
```
Samsung SSD 870 QVO 4TB: 560MB/s
READ: bw=539MiB/s (566MB/s), 539MiB/s-539MiB/s (566MB/s-566MB/s), io=128GiB (137GB), run=242980-242980msec
```

#### BLOW5 C
```
Time for disc reading 1474.799860
Time for getting samples (disc+depress+parse) 1851.329054
        Command being timed: "taskset -a -c 0-7 ./slow5_sequential /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000"
        User time (seconds): 6944.61
        System time (seconds): 234.77
        Percent of CPU this job got: 358%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 33:22.31
        Maximum resident set size (kbytes): 1522728
```

#### BLOW5 CXX
```
Time for disc reading 1471.422431
Time for getting samples (disc+depress+parse) 1713.321039
real time = 1854.048 sec | CPU time = 6163.011 sec | peak RAM = 1.160 GB
        Command being timed: "taskset -a -c 0-7 ./slow5_sequential_cxxpool /data2/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 8 1000"
        User time (seconds): 5898.62
        System time (seconds): 264.41
        Percent of CPU this job got: 332%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 30:54.07
        Maximum resident set size (kbytes): 1216760
```

#### POD5 CXX IO
```
Time for getting samples (disc+depress+parse) 2137.447083
real time = 2333.369 sec | CPU time = 10036.073 sec | peak RAM = 0.952 GB | CPU Usage = 53.8%
        Command being timed: "taskset -a -c 0-7 ./pod5_sequential /data2/tmp/PGXXXX230339_reads.pod5 8"
        User time (seconds): 9480.37
        System time (seconds): 555.71
        Percent of CPU this job got: 430%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 38:53.40
        Maximum resident set size (kbytes): 997744
```

#### POD5 CXX MMAP
```
Time for getting samples (disc+depress+parse) 1903.859728
real time = 1984.545 sec | CPU time = 3614.539 sec | peak RAM = 47.321 GB | CPU Usage = 22.8%
        Command being timed: "taskset -a -c 0-7 ./pod5_sequential /data2/tmp/PGXXXX230339_reads.pod5 8"
        User time (seconds): 3254.28
        System time (seconds): 360.26
        Percent of CPU this job got: 182%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 33:04.56
        Maximum resident set size (kbytes): 49620080
```

### fridge-ssd (32 threads, 1000 batch size, 20X):

```
fio --name=fiotest --filename=/data3/tmp/fiotest  --size=16Gb --rw=read --bs=1M --direct=1 --numjobs=8 --ioengine=libaio --iodepth=8 --group_reporting

cd /home/hasindu/slow5-pod5-bench/slow5
./run_seq.sh /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 32 1000 c &>  fridge_PGXXXX230339_reads_zstd-sv16-zd_32_1000_c_1.log
./run_seq.sh /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 32 1000 cxx &>  fridge_PGXXXX230339_reads_zstd-sv16-zd_32_1000_cxx_1.log
du -h /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5
clean_fscache
/usr/bin/time -v cat /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 > /dev/null

./run_seq.sh /data3/tmp/PGXXXX230339_reads.pod5 32 io &> fridge_PGXXXX230339_reads_32_io_cxx_1.log
./run_seq.sh /data3/tmp/PGXXXX230339_reads.pod5 32 mmap &> fridge_PGXXXX230339_reads_32_mmap_cxx_1.log
```

#### Theoritical:
```

Disk: Samsung 870 QVO 8TB: 560MB/s
READ: bw=540MiB/s (566MB/s), 540MiB/s-540MiB/s (566MB/s-566MB/s), io=128GiB (137GB), run=242776-242776msec
```

#### BLOW5 C
```
Time for disc reading 1478.360469
Time for getting samples (disc+depress+parse) 1629.623530
        Command being timed: "taskset -a -c 0-31 ./slow5_sequential /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 32 1000"
        User time (seconds): 9546.67
        System time (seconds): 324.26
        Percent of CPU this job got: 560%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:20.17
        Maximum resident set size (kbytes): 2629564
```

#### BLOW5 CXX
```
Time for disc reading 1477.932120
Time for getting samples (disc+depress+parse) 1674.696248
real time = 1788.522 sec | CPU time = 8497.014 sec | peak RAM = 2.020 GB
        Command being timed: "taskset -a -c 0-31 ./slow5_sequential_cxxpool /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 32 1000"
        User time (seconds): 7952.15
        System time (seconds): 544.93
        Percent of CPU this job got: 475%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:48.60
        Maximum resident set size (kbytes): 2118020

```

#### cat
```
        Command being timed: "cat /data3/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5"
        User time (seconds): 1.50
        System time (seconds): 274.87
        Percent of CPU this job got: 18%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 24:19.41
```


#### POD5 CXX IO
```
Time for getting samples (disc+depress+parse) 1588.451950
real time = 1763.557 sec | CPU time = 10179.795 sec | peak RAM = 2.011 GB
        Command being timed: "taskset -a -c 0-31 ./pod5_sequential /data3/tmp/PGXXXX230339_reads.pod5 32"
        User time (seconds): 9613.53
        System time (seconds): 566.35
        Percent of CPU this job got: 577%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:23.74
```

#### POD5 CXX MMAP
```
Time for getting samples (disc+depress+parse) 1806.573786
real time = 1971.416 sec | CPU time = 11619.325 sec | peak RAM = 85.854 GB
        Command being timed: "taskset -a -c 0-31 ./pod5_sequential /data3/tmp/PGXXXX230339_reads.pod5 32"
        User time (seconds): 9418.19
        System time (seconds): 2201.17
        Percent of CPU this job got: 589%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 32:51.47
        Maximum resident set size (kbytes): 90024308
```

### fridge-nvme (32 threads, 1000 batch size, 20X):

```
fio --name=fiotest --filename=/data2/tmp/tmp  --size=16Gb --rw=read --bs=1M --direct=1 --numjobs=8 --ioengine=libaio --iodepth=8 --group_reporting
```

#### Theoritical:

```
   Samsung SSD 970 EVO Plus 2TB: 3500MB/s * 3
   READ: bw=9031MiB/s (9469MB/s), 9031MiB/s-9031MiB/s (9469MB/s-9469MB/s), io=128GiB (137GB), run=14514-14514msec
```

#### Extra

gtgpu-ssd (40 threads, 1000 batchsize, 20X dataset):

BLOW5 C:
Time for disc reading 765.783509
Time for getting samples (disc+depress+parse) 982.726540
real time = 1113.924 sec | CPU time = 22285.216 sec | peak RAM = 2.826 GB | CPU Usage = 50.0%
        Command being timed: "taskset -a -c 0-39 ./slow5_sequential /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 40 1000"
        User time (seconds): 21918.94
        System time (seconds): 366.52
        Percent of CPU this job got: 2000%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 18:34.06
        Maximum resident set size (kbytes): 2962792


BLOW5 CXX:
Time for disc reading 758.745975
Time for getting samples (disc+depress+parse) 998.161150
real time = 1108.882 sec | CPU time = 17864.740 sec | peak RAM = 2.347 GB
        Command being timed: "taskset -a -c 0-39 ./slow5_sequential_cxxpool /data/tmp/PGXXXX230339_reads_zstd-sv16-zd.blow5 40 1000"
        User time (seconds): 17200.45
        System time (seconds): 664.40
        Percent of CPU this job got: 1610%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 18:29.02
        Maximum resident set size (kbytes): 2461436

POD5 IO:
Time for getting samples (disc+depress+parse) 1299.319494
real time = 1530.052 sec | CPU time = 21545.128 sec | peak RAM = 2.480 GB
        Command being timed: "taskset -a -c 0-39 ./pod5_sequential /data/tmp/PGXXXX230339_reads.pod5 40"
        User time (seconds): 20662.55
        System time (seconds): 882.74
        Percent of CPU this job got: 1408%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 25:30.18

POD5 MMAP:
Time for getting samples (disc+depress+parse) 616.314473
real time = 872.109 sec | CPU time = 28786.903 sec | peak RAM = 363.729 GB
        Command being timed: "taskset -a -c 0-39 ./pod5_sequential /data/tmp/PGXXXX230339_reads.pod5 40"
        User time (seconds): 21865.40
        System time (seconds): 6921.56
        Percent of CPU this job got: 3300%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 14:32.21
        Maximum resident set size (kbytes): 381397216


gtgpu-nfs (40 threads, 1000 batchsize, 20X dataset):

BLOW5 C:

Time for disc reading 1343.460526
Time for getting samples (disc+depress+parse) 1592.375315
real time = 1770.353 sec | CPU time = 25183.272 sec | peak RAM = 2.846 GB | CPU Usage = 35.6%
        Command being timed: "taskset -a -c 0-39 ./slow5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 40 1000"
        User time (seconds): 24658.23
        System time (seconds): 525.16
        Percent of CPU this job got: 1422%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:30.48
        Maximum resident set size (kbytes): 2983840

BLOW5 CXX:
Time for disc reading 1357.128244
Time for getting samples (disc+depress+parse) 1601.544913
real time = 1798.403 sec | CPU time = 21265.277 sec | peak RAM = 2.409 GB
        Command being timed: "taskset -a -c 0-39 ./slow5_sequential_cxxpool /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 40 1000"
        User time (seconds): 20470.80
        System time (seconds): 794.66
        Percent of CPU this job got: 1182%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 29:58.54
        Maximum resident set size (kbytes): 2525532


POD5 CXX IO:

Time for getting samples (disc+depress+parse) 1684.167183
real time = 1914.319 sec | CPU time = 21494.841 sec | peak RAM = 2.474 GB
        Command being timed: "taskset -a -c 0-39 ./pod5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 40"
        User time (seconds): 20496.04
        System time (seconds): 999.13
        Percent of CPU this job got: 1122%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 31:54.47
        Average shared text size (kbytes): 0
        Average unshared data size (kbytes): 0
        Average stack size (kbytes): 0
        Average total size (kbytes): 0
        Maximum resident set size (kbytes): 2594604

POD5 CXX MMAP:

Time for getting samples (disc+depress+parse) 2923.834019
real time = 3205.875 sec | CPU time = 54649.609 sec | peak RAM = 363.654 GB
        Command being timed: "taskset -a -c 0-39 ./pod5_sequential /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 40"
        User time (seconds): 20175.48
        System time (seconds): 34474.21
        Percent of CPU this job got: 1704%
        Elapsed (wall clock) time (h:mm:ss or m:ss): 53:25.98
        Maximum resident set size (kbytes): 381319132


### Random I/O benchmark