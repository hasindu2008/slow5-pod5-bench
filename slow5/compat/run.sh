#!/bin/bash

FILE_VERSIONS="0.1.0 0.2.0 1.0.0"
LIB_VERSIONS="0.1.0	0.2.0	0.3.0	0.4.0	0.5.0	0.5.1	0.6.0	0.7.0	0.8.0	0.9.0	1.0.0	1.1.0	1.2.0	1.3.0"

die () {
    echo "$1" >&2
    exit 1
}

COMPILE_LIB(){
    wget --no-verbose https://github.com/hasindu2008/slow5lib/archive/refs/tags/v${LIB_VERSION}.tar.gz || die "Error: wget failed"
    tar xf v${LIB_VERSION}.tar.gz || die "Error: tar failed"
    cd slow5lib-${LIB_VERSION}/ || die "Error: cd failed"
    make -j || die "Error: make failed"
    cd ..
    echo "COMPILED"
}

GET_LIB_ALL(){
    rm -rf slow5lib
    mkdir slow5lib || die "Error: mkdir failed"
    cd slow5lib || die "Error: cd failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Compiling slow5lib version ${LIB_VERSION}"
        COMPILE_LIB &> get_lib_${LIB_VERSION}.log
    done
    cd ..
}


GET_SLOW5TOOLS(){
    wget --no-verbose  https://github.com/hasindu2008/slow5tools/releases/download/v${LIB_VERSION}/slow5tools-v${LIB_VERSION}-x86_64-linux-binaries.tar.gz || die "Error: wget failed"
    tar xf slow5tools-v${LIB_VERSION}-x86_64-linux-binaries.tar.gz || die "Error: tar failed"
}

GET_SLOW5TOOLS_ALL(){
    rm -rf slow5tools
    mkdir slow5tools || die "Error: mkdir failed"
    cd slow5tools || die "Error: cd failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "slow5tool version ${LIB_VERSION}"
        GET_SLOW5TOOLS &> get_slow5tools_${LIB_VERSION}.log
    done
    cd ..
}

COMPILE_EXAMPLE(){
    set -x
    gcc slow5_read.c -I slow5lib/slow5lib-${LIB_VERSION}/include slow5lib/slow5lib-${LIB_VERSION}/lib/libslow5.a -lz -o example/slow5_read_${LIB_VERSION} || die "Error: gcc failed"
    set +x
}

COMPILE_EXAMPLE_ALL(){
    rm -rf example/
    mkdir example || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Compiling example version ${LIB_VERSION}"
        COMPILE_EXAMPLE &> example/compile_example_${LIB_VERSION}.log
    done
}


RUN_EXAMPLE(){
    example/slow5_read_${LIB_VERSION} ${FILE_VERSION}.blow5 > run_example/run_example_${FILE_VERSION}_lib_${LIB_VERSION}.out 2> run_example/run_example_${FILE_VERSION}_lib_${LIB_VERSION}.log && SUCCESS=1
    diff -q ${FILE_VERSION}.exp run_example/run_example_${FILE_VERSION}_lib_${LIB_VERSION}.out >/dev/null && SUCCESS=2
}


RUN_EXAMPLE_ALL(){
    rm -rf run_example
    mkdir run_example || die "Error: mkdir failed"
    for  FILE_VERSION in $FILE_VERSIONS
        do
            for LIB_VERSION in ${LIB_VERSIONS}
            do
                SUCCESS=0
                RUN_EXAMPLE
                echo -ne $SUCCESS"\t"
        done
        echo ""
    done

}

CREATE_BLOW5(){
    slow5tools/slow5tools-v${LIB_VERSION}/slow5tools f2s -p1 example.fast5 -o blow5/slow5tools-${LIB_VERSION}.blow5 || die "Error: slow5tools failed"
}

CREATE_BLOW5_ALL(){
    rm -rf blow5
    mkdir blow5 || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Creating blow5 version ${LIB_VERSION}"
        CREATE_BLOW5 &> blow5/create_blow5_${LIB_VERSION}.log
    done
}


RUN_EXAMPLE_2(){
    example/slow5_read_${READ_LIB_VERSION} blow5/slow5tools-${CREATE_LIB_VERSION}.blow5 > run_example_2/run_example_create_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.out 2> run_example_2/run_example_create_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.log && SUCCESS=1
    diff -q example.exp run_example_2/run_example_create_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.out >/dev/null && SUCCESS=2
}


RUN_EXAMPLE_2_ALL(){
    rm -rf run_example_2
    mkdir run_example_2 || die "Error: mkdir failed"
    for  CREATE_LIB_VERSION in $LIB_VERSIONS
        do
            for READ_LIB_VERSION in ${LIB_VERSIONS}
            do
                SUCCESS=0
                RUN_EXAMPLE_2
                echo -ne $SUCCESS"\t"
        done
        echo ""
    done

}


GET_LIB_ALL
GET_SLOW5TOOLS_ALL
COMPILE_EXAMPLE_ALL
CREATE_BLOW5_ALL

RUN_EXAMPLE_ALL > stability_format_matrix.txt
RUN_EXAMPLE_2_ALL > stability_libversion_matrix.txt