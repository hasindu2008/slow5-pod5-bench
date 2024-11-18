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

Build slow5_sequential and pod5_sequential on an ARM system:

	cd slow5-pod5-bench/slow5/slow5lib && make clean
	make -j CC=gcc-10 slow5_mt=1 zstd_local=../zstd/lib/
	cd ..
	gcc-10 -static -Wall -O3 -g -I slow5lib/include/ -o slow5_sequential sequential.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp
	g++-10 -static -Wall -O3 -g -I slow5lib/include/ -I ../pod5/cxxpool/src -o slow5_sequential_cxxpool sequential_cxxpool.cpp slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lpthread # TODO: aborts unexpectedly
	g++-10 -static -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib64/libpod5_format.a pod5_format/lib64/libarrow.a pod5_format/lib64/libzstd.a -lm -lz -fopenmp -lpthread

Copy over the binaries:

	adb push slow5_sequential slow5_sequential_cxxpool pod5_sequential clean_fscache time /data/local/tmp/

Run the experiments:

	adb shell
	cd /data/local/tmp
	for i in $(seq 1 5)
	do
		./clean_fscache && ./time -v taskset -a FF ./slow5_sequential /storage/emulated/data/PGXXXX230339_reads_500k_zstd-sv16-zd.blow5 8 1000 > /dev/null 2> slow5_sequential-$i.err
		./clean_fscache && ./time -v taskset -a FF ./pod5_sequential /storage/emulated/data/PGXXXX230339_reads_500k.pod5 8 > /dev/null 2> pod5_sequential-$i.err
	done

TODO:
- get slow5_sequential_cxxpool successfully statically executing
