Mac
===
How to benchmark on Mac.

pod5
----
See which compiler was used to create the binary:

	objdump -s pod5_format/lib/libpod5_format.a | grep clang -i -B1 -A2 -m1

	Contents of section __DWARF,__debug_str:
	 160d8b 4170706c 6520636c 616e6720 76657273  Apple clang vers
	 160d9b 696f6e20 31332e31 2e362028 636c616e  ion 13.1.6 (clan
	 160dab 672d3133 31362e30 2e32312e 322e3329  g-1316.0.21.2.3)

Install brew:

	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo >> /Users/gtg/.zprofile
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/gtg/.zprofile
	eval "$(/opt/homebrew/bin/brew shellenv)"

Install clang-13 and wget:

	brew install llvm@13 wget

Add clang-13 to the PATH. For persistent behaviour, add this to ~/.zshrc:

	export PATH="/opt/homebrew/opt/llvm@13/bin:$PATH"

Add the following to random.cpp:

	#include <array>

Change build.sh:

	export CC=clang
	export CXX=clang++

	...

	test -e pod5_format/lib/libpod5_format.a || die "pod5_format not found"

	$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/* -lm -lz -fopenmp -lpthread -lunwind -L/opt/homebrew/Cellar/llvm@13/13.0.1_2/lib/ || die "Failed to build pod5_sequential"
	$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib/* -lm -lz -fopenmp -lpthread -lunwind -L/opt/homebrew/Cellar/llvm@13/13.0.1_2/lib/ || die "Failed to build pod5_random"
	install_name_tool -add_rpath pod5_format/lib pod5_sequential
	install_name_tool -add_rpath pod5_format/lib pod5_random

I don't think it is possible to set the cpu affinity of a process on Mac. There
is a related API <https://developer.apple.com/library/archive/releasenotes/Performance/RN-AffinityAPI/#//apple_ref/doc/uid/TP40006635-CH1-DontLinkElementID_2>,
but it appears to be useless.

Change run_seq.sh and similarly run_rand.sh:

	purge || die "purge failed" # requires root privileges

	...

	/usr/bin/time -pl "./$SEQ_CXX" "$POD5" "$T" > /dev/null

Get number of logical cores:

	getconf _NPROCESSORS_ONLN

Benchmark:

	./build.sh
	for i in $(seq 1 5)
	do
		sudo ./run_seq.sh <pod5> 8 io > /dev/null 2> pod5_sequential_io-$i.err
		sudo ./run_seq.sh <pod5> 8 mmap > /dev/null 2> pod5_sequential_mmap-$i.err
	done

slow5
-----
Change install-zstd.sh:

	export CC=clang
	export CXX=clang++

If you want the slow5lib shared library, change slow5lib/Makefile:

	$(SHAREDLIB): $(OBJ) $(SVBLIB) $(SVB16LIB) $(zstd_local)/libzstd.dylib

Change build.sh and similarly build_cxxpool.sh:

	export CC=clang
	export CXX=clang++

	cd slow5lib && make clean
	# target lib/libslow5.a
	make -j CC=$CC slow5_mt=1 zstd_local=../zstd/lib/ lib/libslow5.a || die "Building slow5lib failed"
	cd ..

	# adding -lunwind
	$CC -Wall -O3 -g -I slow5lib/include/ -I slow5lib/src -o slow5_sequential sequential.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lunwind -L/opt/homebrew/Cellar/llvm@13/13.0.1_2/lib/ || die "compilation failed"
	$CC -Wall -O3 -g -I slow5lib/include/ -o slow5_random random.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lunwind -L/opt/homebrew/Cellar/llvm@13/13.0.1_2/lib/ || die "compilation failed"

Change run_seq.sh and similarly run_rand.sh:

	purge || die "purge failed" # requires root privileges

	...

		/usr/bin/time -pl "./$SEQ" "$SLOW5" "$T" "$B" > /dev/null

	...

		/usr/bin/time -pl "./$SEQ_CXX" "$SLOW5" "$T" "$B" > /dev/null

Benchmark:

	./install-zstd.sh
	./build.sh
	for i in $(seq 1 5)
	do
		sudo ./run_seq.sh <slow5> 8 1000 c > /dev/null 2> slow5_sequential_c-$i.err
		sudo ./run_seq.sh <slow5> 8 1000 cxx > /dev/null 2> slow5_sequential_cxx-$i.err
	done
