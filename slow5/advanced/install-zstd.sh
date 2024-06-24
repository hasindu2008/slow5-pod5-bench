#!/bin/bash

#Todo : use curl as a failsafe

. "$(dirname $0)"/cf.sh

# terminate script
die() {
    echo "$1" >&2
    exit 1
}

test -e zstd-v${ZSTD_VER}.tar.gz && rm zstd-v${ZSTD_VER}.tar.gz
test -d zstd && rm -r zstd

wget https://github.com/facebook/zstd/archive/refs/tags/v${ZSTD_VER}.tar.gz -O zstd-v${ZSTD_VER}.tar.gz || die "Downloading zstd source failed"
tar -xzf zstd-v${ZSTD_VER}.tar.gz || die "extracting failed"
rm zstd-v${ZSTD_VER}.tar.gz
mv zstd-${ZSTD_VER} zstd || die "Moving zstd-v${ZSTD_VER} to zstd failed"
cd zstd || die "cd to zstd failed"
make -j8 || die " Building zstd failed"
echo "Successfully installed zstd to ./zstd."
