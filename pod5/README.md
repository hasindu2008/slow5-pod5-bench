# pod5 bench

For equivalent conditions with vbz in POD5, must use svb16 in BLOW5. Compilation of pod5 library is hard. So let us download POD5 library binaries.

1. Download prebuilt pod5 library binaries

```
wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
export LD_LIBRARY_PATH=$PWD/pod5_format/lib
```

Note: for ARM64 Linux wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-arm64.tar.gz

Note: FOr mac https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-osx-11.0-arm64.tar.gz

2. Compile the benchmarks using `./build.sh`

3. Run sequential benchmark
```
./run_seq.sh reads.pod5 8 io # traditional io
./run_seq.sh reads.pod5 8 mmap # mmap
```
4. Run random (not finalized)
```
./run_rand.sh <pod5> <list> <thr> <batch> io # traditional io
./run_rand.sh <pod5> <list> <thr> <batch> mmap # mmap
```
