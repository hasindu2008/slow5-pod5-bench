#!/bin/sh
# you set BLOW5_IN then benchmark slow5lib
#
# usage: ./bench.sh
# recommended: ./bench.sh > bench.out 2>&1
#
# logs are printed
# - script invocation
# - date and time
# - compilers (cc, gcc, g++) used
# - local zstd library version
# - slow5tools commits used (set in TOOLS_COMMIT and TOOLS_LIB_COMMIT)
# - slow5lib commit used (set in LIB_COMMIT)
# - slow5-pod5-bench commit used
# - BLOW5_IN path
# - BLOW5_OUT path
#
# local zstd library is created if not already and the version is checked
# slow5tools is cloned if not already and compiled using latest vbz commits and
# local zstd library
#
# blow5 is created with zstd record and svb16-zd signal compression using local
# slow5tools to BLOW5_OUT, indexed and random readid list created
#
# to skip creating the blow5 set BLOW5_IN and BLOW5_OUT to the same path
# note that using a different zstd library version to create the blow5 may give
# different benchmarking results
#
# local slow5lib is compiled using latest bench commit and the build scripts are
# run
#
# benchmarch scripts RAND, SEQ (and optionally SEQ_CXX) are run using a range of
# THREADS and fixed BATCH_SZ with the file system cache cleared using clean_fscache
#
# compilation output can be used by you to check that
# - slow5 library uses
#   - options -g -Wall -O3 -std=c99
#   - streamvbyte16 compiled with
#     - SIMD enabled -msse4.1
#     - options -O3
# - benchmark compiled with
#   - options -g -Wall -O2

# Set this path to the blow5 file to run the benchmarks on. Note that it can be
# any valid blow5 or slow5 file; we will convert it in this script and write the
# file to BLOW5_OUT. In which case, you may want to set BLOW5_OUT to a path
# which will have enough space.

BLOW5_IN= # TODO

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ -z "$BLOW5_IN" ]
then
	die 'Edit this file and set BLOW5_IN'
fi

BLOW5_OUT=out.blow5 # path to output blow5 file
IDS=reads.list # path to output readid list
TMP="$BLOW5_OUT.tmp" # temporary benchmarking output
RUN_CXX= # set to non-empty to also run SEQ_CXX benchmark

ZSTD=zstd # path to local zstd repo
ZSTD_INC="$ZSTD/lib"
ZSTD_VER=1.5.4
ZSTD_STATIC="$ZSTD/lib/libzstd.a"
ZSTD_SHARED="$ZSTD/lib/libzstd.so.$ZSTD_VER"
TOOLS_LOCAL=slow5tools # path to local slow5tools repo
TOOLS_URL=https://github.com/hasindu2008/slow5tools
TOOLS_COMMIT=8a366bf6dffe0c94fd0ec148cca22f09e47c31e5 # latest upstream vbz
TOOLS_LIB_COMMIT=8efc1f704f864ba5e29c75ffa85ebb248007bb46 # latest upstream vbz
TOOLS="$TOOLS_LOCAL/slow5tools"
TOOLS_ZSTD=../ # relative path from TOOLS_LOCAL to ZSTD
LIB_LOCAL=slow5lib # path to local slow5lib repo
LIB_COMMIT=a90d45cf0aa53a32205f1fbadb8b8b1a132cd085 # latest local bench
RAND=slow5_random
SEQ=slow5_sequential
SEQ_CXX=slow5_sequential_cxxpool
RAND_OUT="$BLOW5_OUT.$RAND.stdout"
SEQ_OUT="$BLOW5_OUT.$SEQ.stdout"
SEQ_CXX_OUT="$SEQ_OUT" # SEQ_CXX output does not differ from SEQ
THREADS='1 2 4 8 16'
BATCH_SZ=1024
TASKSET_CPUS=1

clfs()
{
	clean_fscache || die 'Failed to clean the file system cache'
}

bench()
{
	/usr/bin/time -v taskset -c "$TASKSET_CPUS" $@
}

diffchk()
{
	if ! [ -e "$1" ]
	then
		cp "$2" "$1" || die "copy '$2' to '$1' failed"
	else
		diff -q "$1" "$2" || die "'$1' and '$2' differ"
	fi
}

# log information
echo \
"cmd: $0 $*
$(date)
cc version: $(cc --version)
gcc version: $(gcc --version)
g++ version: $(g++ --version)
zstd version: $ZSTD_VER
slow5tools commit: $TOOLS_COMMIT
slow5tools slow5lib commit: $TOOLS_LIB_COMMIT
local slow5lib commit: $LIB_COMMIT
slow5-pod5-bench commit: $(git log | head -n1)
BLOW5_IN: $BLOW5_IN
BLOW5_OUT: $BLOW5_OUT"

# checkout local slow5lib
git -C "$LIB_LOCAL" checkout "$LIB_COMMIT" \
	|| die "git failed to checkout $LIB_LOCAL to commit $LIB_COMMIT"

# download and compile local zstd
if ! [ -e "$ZSTD_STATIC" ]
then
	./install-zstd.sh || die 'Failed to download and compile local zstd'
fi

# check shared zstd library with version exists
if ! [ -e "$ZSTD_SHARED" ]
then
	die "zstd library version $ZSTD_VER does not exist"
fi

# download and compile slow5tools
if ! [ -d "$TOOLS_LOCAL" ]
then
	git clone --recurse-submodules "$TOOLS_URL" "$TOOLS_LOCAL" \
		|| die "git failed to clone $TOOLS_URL to $TOOLS_LOCAL"
fi
git -C "$TOOLS_LOCAL" checkout "$TOOLS_COMMIT" \
	|| die "git failed to checkout $TOOLS_LOCAL to commit $TOOLS_COMMIT"
git -C "$TOOLS_LOCAL/slow5lib" checkout "$TOOLS_LIB_COMMIT" \
	|| die "git failed to checkout $TOOLS_LOCAL/slow5lib to commit $TOOLS_LIB_COMMIT"
make -C "$TOOLS_LOCAL" clean \
	|| die "make clean failed in $TOOLS_LOCAL"
make -C "$TOOLS_LOCAL" -j slow5_mt=1 zstd_local="$TOOLS_ZSTD/$ZSTD_INC" \
	disable_hdf5=1 LIBS="$TOOLS_ZSTD/$ZSTD_STATIC" \
	|| die "make failed in $TOOLS_LOCAL"

if [ "$BLOW5_IN" != "$BLOW5_OUT" ]
then
	# create blow5 with zstd/svb16-zd record/signal compression
	"$TOOLS" view "$BLOW5_IN" -c zstd -s svb16-zd -o "$BLOW5_OUT" \
		|| die "Failed to create $BLOW5_OUT"
fi
# index the blow5
"$TOOLS" index "$BLOW5_OUT" \
	|| die "Failed to index $BLOW5_OUT"
# generate random readid list
"$TOOLS" skim --rid "$BLOW5_OUT" | sort -R > "$IDS" \
	|| die 'Failed to generate random readid list'

# compile slow5lib and benchmarks
./build.sh || die 'build.sh failed'
if [ -n "$RUN_CXX" ]
then
	./build_cxxpool.sh || die 'build_cxxpool.sh failed'
fi

# prep for diffchk
rm -f "$RAND_OUT" "$SEQ_OUT" "$SEQ_CXX_OUT"

# run the benchmark
for i in $THREADS
do
	# random test
	stderr="$BLOW5_OUT.$RAND.$i.$BATCH_SZ.stderr"
	clfs
	bench "./$RAND" "$BLOW5_OUT" "$IDS" "$i" "$BATCH_SZ" \
		> "$TMP" 2> "$stderr" \
		|| die "$RAND failed for $i threads"
	diffchk "$RAND_OUT" "$TMP"

	# sequential test
	stderr="$BLOW5_OUT.$SEQ.$i.$BATCH_SZ.stderr"
	clfs
	bench "./$SEQ" "$BLOW5_OUT" "$i" "$BATCH_SZ" \
		> "$TMP" 2> "$stderr" \
		|| die "$SEQ failed for $i threads"
	diffchk "$SEQ_OUT" "$TMP"

	if [ -n "$RUN_CXX" ]
	then
		# sequential cxxpool test
		stderr="$BLOW5_OUT.$SEQ_CXX.$i.$BATCH_SZ.stderr"
		clfs
		bench "./$SEQ_CXX" "$BLOW5_OUT" "$i" "$BATCH_SZ" \
			> "$TMP" 2> "$stderr" \
			|| die "$SEQ_CXX failed for $i threads"
		diffchk "$SEQ_CXX_OUT" "$TMP"
	fi
done

rm -f "$TMP"
