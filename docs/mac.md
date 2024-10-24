Mac
===
How to benchmark on Mac.

pod5
----
See which compiler was used to create the binary:

	objdump -s pod5_format/lib/libpod5_format.a | grep clang -i -B1 -A2 -m1

	Contents of section __DWARF,__debug_str:
	 1537ec 4170706c 6520636c 616e6720 76657273  Apple clang vers
	 1537fc 696f6e20 31342e30 2e302028 636c616e  ion 14.0.0 (clan
	 15380c 672d3134 30302e30 2e32392e 32303229  g-1400.0.29.202)

Install clang-14:

	brew install llvm@14

Add clang-14 to the PATH. For persistent behaviour, add this to ~/.zshrc:

	export PATH="/opt/homebrew/opt/llvm@14/bin:$PATH"

Add the following to random.cpp:

	#include <array>

Change build.sh:

	export CC=clang
	export CXX=clang++

	...

	test -e pod5_format/lib/libpod5_format.a || die "pod5_format not found"

	$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/*.a -lm -lz -fopenmp -lpthread -lunwind || die "Failed to build pod5_sequential"
	$CXX -Wall -O3 -g -I pod5_format/include -I cxxpool/src -o pod5_random random.cpp pod5_format/lib/*.a -lm -lz -fopenmp -lpthread -lunwind || die "Failed to build pod5_random"

I don't think it is possible to set the cpu affinity of a process on Mac. There
is a related API <https://developer.apple.com/library/archive/releasenotes/Performance/RN-AffinityAPI/#//apple_ref/doc/uid/TP40006635-CH1-DontLinkElementID_2>,
but it appears to be useless.

Change run_seq.sh and similarly run_rand.sh:

	purge || die "purge failed" # requires root privileges

	...

	/usr/bin/time -pl "./$SEQ_CXX" "$POD5" "$T" > /dev/null

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
	$CC -Wall -O3 -g -I slow5lib/include/ -I slow5lib/src -o slow5_sequential sequential.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lunwind || die "compilation failed"
	$CC -Wall -O3 -g -I slow5lib/include/ -o slow5_random random.c slow5lib/lib/libslow5.a zstd/lib/libzstd.a -lm -lz -fopenmp -lunwind || die "compilation failed"

Change run_seq.sh and similarly run_rand.sh:

	purge || die "purge failed" # requires root privileges

	...

		/usr/bin/time -pl "./$SEQ" "$SLOW5" "$T" "$B" > /dev/null

	...

		/usr/bin/time -pl "./$SEQ_CXX" "$SLOW5" "$T" "$B" > /dev/null
