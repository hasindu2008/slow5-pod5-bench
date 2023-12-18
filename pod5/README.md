# pod5 bench

For equivalent conditions with vbz in POD5, must use svb16 in BLOW5.

1. Download prebuilt pod5 library binaries

```
wget https://github.com/nanoporetech/pod5-file-format/releases/download/0.3.2/lib_pod5-0.3.2-linux-x64.tar.gz
tar -xvf lib_pod5-0.3.2-linux-x64.tar.gz -C pod5_format
```
2. CMake build
```
mkdir build
cd build
cmake ..
make -j
```

3. Run sequential
```
./build/pod5_convert_to_pa reads.pod5 8
```
4. Run random
```
./build/pod5_convert_to_pa_rand reads.pod5 readlist 1 100
```
