# pod5 bench

For equivalent conditions with vbz in POD5, must use svb16 in BLOW5. Compilation of pod5 library is hard. So let us download POD5 library binaries.

1. Download prebuilt pod5 library binaries

```
wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
export LD_LIBRARY_PATH=$PWD/pod5_format/lib
```

2. Compile the benchmarks using `./build.sh`

3. Run sequential benchmark
```
./run_seq.sh reads.pod5 8 mmap # mmap
./run_seq.sh reads.pod5 8 io # traditional io

```
4. Run random
```
./run_rand.sh <pod5> <list> <thr> <batch> mmap # mmap
./run_rand.sh <pod5> <list> <thr> <batch> io # traditional io
```
