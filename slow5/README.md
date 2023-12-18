# slow5 bench

For equivalent conditions with vbz in POD5, must use svb16 in BLOW5.

1. Prepare the input for the benchmark

```
git clone --recursive https://github.com/hasindu2008/slow5tools -b vbz
cd slow5tools
make zstd=1 -j
./slow5tools view -c zstd -s svb16-zd PGXX22394_reads_1000.blow5 -o zstd-sv16-zd.blow5
```

Double check if they are correct:
```
./slow5tools stats zstd-sv16-zd.blow5
```

`record compression method` must be  `zstd` and `signal compression method` must be `svb16-zd`.


2. Compile the benchmarks using `./build.sh` and run the benchmarks