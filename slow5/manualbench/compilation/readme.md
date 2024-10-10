# compiling with defaults

## Gadi

```
cd /g/data/ox63/hasindu/
mkdir slow5-pod5-bench-default-compile && cd slow5-pod5-bench-default-compile
git clone --recursive git@github.com:hasindu2008/slow5-pod5-bench.git && cd slow5-pod5-bench
cd slow5/slow5lib
git checkout dev
git checkout 72e07865fe7e2a611ece6748c566d950081e0967
cd ..
~/hasindu2008.git/slow5tools/scripts/install-zstd.sh

cd slow5lib && make clean
make -j slow5_mt=1 zstd_local=../zstd/lib/
cd ..

g++ -Wall -O2 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_sequential_cxxpool sequential_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lpthread
g++ -Wall -O2 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_random_cxxpool random_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lpthread
```