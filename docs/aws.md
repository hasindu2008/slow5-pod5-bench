# AWS setup

```
aws s3 cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads.pod5 s3://slow5test/
aws s3 cp /home/hasindu/scratch/hg2_prom_lsk114_5khz/PGXXXX230339_reads_zstd-sv16-zd.blow5 s3://slow5test/
```

1. Select c5a.16xlarge, Ubuntu 24.04, 32GB gp3 disk, make sure to add key-pair
2. ssh with the key
3. copy/clone the slow5-pod5-bench recursively [check if commit is c254055ea7811ce3daec541141a8608d5dc15243 for slow5lib]

4. install packages
```
sudo apt-get update
sudo apt-get install -y gcc-10 g++-10 zlib1g-dev make
```

5. follow instructions in [slow5-pod5-bench/slow5](../slow5) to build the slow5 benchmarks or just the following:

```
cd slow5/
./build_cxx.sh
```

7. follow instructions in [slow5-pod5-bench/pod5](../pod5) to build the pod5 benchmarks  or just the following:
```
cd pod5/
wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
export LD_LIBRARY_PATH=$PWD/pod5_format/lib
./build.sh
```

   
