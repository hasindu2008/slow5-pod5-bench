#!/bin/bash

#Todo : use curl as a failsafe

# terminate script
die() {
    echo -e "${RED}$1${NC}" >&2
    echo
    exit 1
}

JE_VERSION=
test -e jemalloc-5.2.1.tar.bz2 && rm jemalloc-5.2.1.tar.bz2
test -d jemalloc && rm -r jemalloc

export CC=gcc-10
export CXX=g++-10

wget https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 -O jemalloc-5.2.1.tar.bz2 || die "Downloading jemalloc source failed"
tar -xf jemalloc-5.2.1.tar.bz2 || die "extracting failed"
rm jemalloc-5.2.1.tar.bz2
mv jemalloc-5.2.1 jemalloc || die "Moving jemalloc-5.2.1 to jemalloc failed"
cd jemalloc || die "cd to jemalloc failed"
./configure || die "Configuring jemalloc failed"
make -j8 || die " Building jemalloc failed"
echo "Successfully installed jemalloc to ./jemalloc."
