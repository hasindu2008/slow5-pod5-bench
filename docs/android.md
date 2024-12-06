Android
=======
This is a guide to benchmarking on Android using ADB.

Setup
-----
Activate "Developer options" by clicking on "Build number" several times. Then,
enable "USB debugging".

Connect the phone to a computer over USB. In "USB Preferences" select "USB
tethering".

	adb devices

Copy the data to the computer, then to the phone:

	rsync -P gpg:/data/slow5-testdata/hg2_prom_lsk114_5khz_subsample/PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 gpg:/data/slow5-testdata/hg2_prom_lsk114_5khz_subsample/PGXXXX230339_reads_500k.pod5 .
	slow5tools index PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 # vbz branch
	adb shell mkdir /storage/emulated/data
	adb push PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 PGXXXX230339_reads_500k_zstd-sv16-zd.blow5.idx PGXXXX230339_reads_500k.pod5 /storage/emulated/data/

Build the GNU time utility on an ARM system:

	wget https://mirrors.middlendian.com/gnu/time/time-1.9.tar.gz
	wget https://mirrors.middlendian.com/gnu/time/time-1.9.tar.gz.sig https://ftp.gnu.org/gnu/gnu-keyring.gpg
	gpg2 --verify --keyring ./gnu-keyring.gpg time-1.9.tar.gz.sig
	tar xf time-1.9.tar.gz
	cd time-1.9
	./configure LDFLAGS='-static'
	make

Change clean_fscache2.c:

	#define FILE_TMP_PREFIX "/storage/emulated/data/tmp_file"
	#define NUM_THERADS 8
	#define GB_PER_THREAD 2

Build clean_fscache on an ARM system:

	gcc -static -Wall clean_fscache2.c -O2 -o clean_fscache -lpthread

Build the slow5 benchmarking programs on an ARM system:

	cd slow5-pod5-bench/slow5/slow5lib && make clean
	make -j CC=gcc-10 slow5_mt=1 zstd_local=../zstd/lib/
	cd ..
	gcc-10 -static -Wall -O3 -g -I slow5lib/include/ -o slow5_sequential sequential.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp
	gcc-10 -static -Wall -O3 -g -I slow5lib/include/ -o slow5_random random.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp
	g++-10 -static -Wall -O3 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_sequential_cxxpool sequential_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -Wl,--whole-archive -lpthread -Wl,--no-whole-archive
	g++-10 -static -Wall -O3 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_random_cxxpool random_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -Wl,--whole-archive -lpthread -Wl,--no-whole-archive

Since libpod5 v0.3.2 does not bundle Zstd nor Arrow into their release, we must
build these ourselves! Run the following on an ARM system:

	git clone https://github.com/nanoporetech/pod5-file-format
	cd pod5-file-format/
	git submodule update --init --recursive
	git checkout 0.3.2
	python3 -m pip install 'conan<2'
	# Fix missing package
	sed 's/flatbuffers\/2.0.0@nanopore\/testing/flatbuffers\/2.0.0@/' conanfile.py -i
	mkdir build
	cd build
	export CC=gcc-10 CXX=g++-10
	conan install --build=missing -s build_type=Release -s compiler.version=10 ..

Build the pod5 benchmarking programs on an ARM system:

	g++-10 -static -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib64/libpod5_format.a ~/.conan/data/arrow/8.0.0/_/_/package/<id>/lib/libarrow.a ~/.conan/data/zstd/1.5.4/_/_/package/<id>/lib/libzstd.a -lm -lz -fopenmp -lpthread
	g++-10 -static -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib64/libpod5_format.a ~/.conan/data/arrow/8.0.0/_/_/package/<id>/lib/libarrow.a ~/.conan/data/zstd/1.5.4/_/_/package/<id>/lib/libzstd.a -lm -lz -fopenmp -lpthread

Copy over the binaries:

	adb shell mkdir -p /data/local/tmp/slow5-pod5-bench/slow5/ /data/local/tmp/slow5-pod5-bench/slow5/
	adb push clean_fscache time /data/local/tmp/
	adb push slow5_sequential_cxxpool slow5_random_cxxpool /data/local/tmp/slow5-pod5-bench/slow5/
	adb push pod5_sequential pod5_random /data/local/tmp/slow5-pod5-bench/pod5/

Benchmark
---------
Run the experiments:

	adb shell
	export PATH=/data/local/tmp/:$PATH
	export TASKSET_AFFINITY=FF # processors 0-7
	cd /data/local/tmp/slow5-pod5-bench/slow5
	for i in $(seq 1 5)
	do
		clean_fscache && command time -v taskset -a "$TASKSET_AFFINITY" ./slow5_sequential <slow5> 8 1000 > /dev/null 2> slow5_sequential-$i.err
		clean_fscache && command time -v taskset -a "$TASKSET_AFFINITY" ./slow5_sequential_cxxpool <slow5> <list> 8 1000 > /dev/null 2> slow5_sequential_cxxpool-$i.err
	done
	cd /data/local/tmp/slow5-pod5-bench/pod5
	for i in $(seq 1 5)
	do
		clean_fscache && command time -v taskset -a "$TASKSET_AFFINITY" ./pod5_sequential <pod5> 8 > /dev/null 2> pod5_sequential_mmap-$i.err
		clean_fscache && POD5_DISABLE_MMAP_OPEN=1 command time -v taskset -a "$TASKSET_AFFINITY" ./pod5_sequential <pod5> 8 > /dev/null 2> pod5_sequential_io-$i.err
	done

Other
-----
Building Arrow:

	wget https://archive.apache.org/dist/arrow/arrow-8.0.0/apache-arrow-8.0.0.tar.gz

	# Verify download (if you care)
	wget https://archive.apache.org/dist/arrow/arrow-8.0.0/apache-arrow-8.0.0.tar.gz.asc https://archive.apache.org/dist/arrow/arrow-8.0.0/apache-arrow-8.0.0.tar.gz.sha512 https://archive.apache.org/dist/arrow/KEYS
	gpg --import KEYS
	gpg --verify apache-arrow-8.0.0.tar.gz.asc
	sha512sum -c apache-arrow-8.0.0.tar.gz.sha512

	# Build arrow
	tar xf apache-arrow-8.0.0.tar.gz
	cd apache-arrow-8.0.0/cpp
	mkdir build

	cd build
	cmake ..
	make -j
