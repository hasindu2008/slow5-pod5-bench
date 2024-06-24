#!/bin/sh
# download and compile slow5tools
# usage: ./install-tools.sh

. ./cf.sh

die()
{
	echo "$1" 1>&2
	exit 1
}

if ! [ -e "$ZSTD_SHARED" ]
then
	./install-zstd.sh || die 'Failed to download and compile local zstd'
fi

if ! [ -d "$TOOLS" ]
then
	git clone --recurse-submodules "$TOOLS_URL" "$TOOLS" \
		|| die "git failed to clone $TOOLS_URL to $TOOLS"
fi
git -C "$TOOLS" checkout "$TOOLS_COMMIT" \
	|| die "git failed to checkout $TOOLS to commit $TOOLS_COMMIT"
git -C "$TOOLS/slow5lib" checkout "$TOOLS_LIB_COMMIT" \
	|| die "git failed to checkout $TOOLS/slow5lib to commit $TOOLS_LIB_COMMIT"
make -C "$TOOLS" clean || die "make clean failed in $TOOLS"
make -C "$TOOLS" -j slow5_mt=1 zstd_local="$(readlink -f $ZSTD_INC)" \
	disable_hdf5=1 LIBS="$(readlink -f $ZSTD_STATIC)" \
	|| die "make failed in $TOOLS"
