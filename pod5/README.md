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
./pod5_sequential reads.pod5 8
```
4. Run random (not finalized)
```
./pod5_convert_to_pa_rand reads.pod5 readlist 1 100
```
