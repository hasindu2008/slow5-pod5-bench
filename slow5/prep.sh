#!/bin/sh
# usage: ./prep.sh <in_slow5> <out_blow5> <out_ids>
#
# Given an input slow5 or blow5 file, convert it to a blow5 file with zstd
# record and svb16-zd signal compression. The blow5 file is then indexed and a
# random list of all readids is created.
#
# Local zstd library is created if not already and the version is checked.
# slow5tools is cloned if not already and compiled using latest vbz commits and
# local zstd library.

USAGE="usage: $0 <in_slow5> <out_blow5> <out_ids>"

die()
{
	echo "$1" 1>&2
	exit 1
}

if [ $# -ne 3 ]
then
	die "$USAGE"
fi

BLOW5_IN=$1
BLOW5_OUT=$2
IDS=$3

ZSTD=zstd # path to local zstd repo
ZSTD_INC=$ZSTD/lib
ZSTD_VER=1.5.4
ZSTD_STATIC=$ZSTD/lib/libzstd.a
ZSTD_SHARED=$ZSTD/lib/libzstd.so.$ZSTD_VER
TOOLS_LOCAL=slow5tools # path to local slow5tools repo
TOOLS_URL=https://github.com/hasindu2008/slow5tools
TOOLS_COMMIT=8a366bf6dffe0c94fd0ec148cca22f09e47c31e5 # latest upstream vbz
TOOLS_LIB_COMMIT=8efc1f704f864ba5e29c75ffa85ebb248007bb46 # latest upstream vbz
TOOLS=$TOOLS_LOCAL/slow5tools
TOOLS_ZSTD=../ # relative path from TOOLS_LOCAL to ZSTD

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

# create blow5 with zstd/svb16-zd record/signal compression
"$TOOLS" view "$BLOW5_IN" -c zstd -s svb16-zd -o "$BLOW5_OUT" \
	|| die "Failed to create $BLOW5_OUT"
# index the blow5
"$TOOLS" index "$BLOW5_OUT" \
	|| die "Failed to index $BLOW5_OUT"
# generate random readid list
"$TOOLS" skim --rid "$BLOW5_OUT" | sort -R > "$IDS" \
	|| die 'Failed to generate random readid list'
