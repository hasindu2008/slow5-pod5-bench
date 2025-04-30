#!/bin/bash

FILE_VERSIONS="0.1.0  0.2.0"
LIB_VERSIONS="0.1.0  0.2.0  0.3.0  0.4.0  0.5.0  0.5.1  0.6.0  0.7.0  0.8.0  0.9.0  1.0.0  1.1.0  1.2.0  1.3.0"

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

COMPILE_PROGRAME(){
    set -x
    gcc slow5_read.c -I slow5lib/slow5lib-${LIB_VERSION}/include slow5lib/slow5lib-${LIB_VERSION}/lib/libslow5.a -lz -o program/slow5_read_${LIB_VERSION} || die "Error: gcc failed"
    set +x
}

COMPILE_PROGRAME_ALL(){
    rm -rf program/
    mkdir program || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Compiling program version ${LIB_VERSION}"
        COMPILE_PROGRAME &> program/compile_program_${LIB_VERSION}.log
    done
}

COMPILE_AND_RUN_EXAMPLE(){
    set -x
    gcc slow5_example.c -I slow5lib/slow5lib-${LIB_VERSION}/include slow5lib/slow5lib-${LIB_VERSION}/lib/libslow5.a -lz -o example/slow5_example_${LIB_VERSION} || die "Error: gcc failed"
    ./example/slow5_example_${LIB_VERSION} blow5/slow5tools-${LIB_VERSION}.blow5 > example/example_lib_${LIB_VERSION}.out 2> example/example_lib_${LIB_VERSION}.log || die "Error: example failed"
    set +x
    diff -q example.exp example/example_lib_${LIB_VERSION}.out >/dev/null || die "Error: diff failed"

}

COMPILE_EXAMPLE_AND_RUN_ALL(){
    rm -rf example/
    mkdir example || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Compiling and running example version ${LIB_VERSION}"
        COMPILE_AND_RUN_EXAMPLE &> example/example_${LIB_VERSION}.log
    done
}


RUN_FILE_VERSION_CHECK(){
    program/slow5_read_${LIB_VERSION} ${FILE_VERSION}.blow5 > run_file_version_check/run_${FILE_VERSION}_lib_${LIB_VERSION}.out 2> run_file_version_check/run_${FILE_VERSION}_lib_${LIB_VERSION}.log && SUCCESS=1
    diff -q file.exp run_file_version_check/run_${FILE_VERSION}_lib_${LIB_VERSION}.out >/dev/null && SUCCESS=2
}


RUN_FILE_VERSION_CHECK_ALL(){
    rm -rf run_file_version_check
    mkdir run_file_version_check || die "Error: mkdir failed"
    for  FILE_VERSION in $FILE_VERSIONS
        do
            for LIB_VERSION in ${LIB_VERSIONS}
            do
                SUCCESS=0
                RUN_FILE_VERSION_CHECK
                echo -ne $SUCCESS"\t"
        done
        echo ""
    done

}

CREATE_BLOW5(){
    slow5tools/slow5tools-v${LIB_VERSION}/slow5tools f2s -p1 file.fast5 -o blow5/slow5tools-${LIB_VERSION}.blow5 || die "Error: slow5tools failed"
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


RUN_LIB_VERSION_CHECK(){
    program/slow5_read_${READ_LIB_VERSION} blow5/slow5tools-${CREATE_LIB_VERSION}.blow5 > run_lib_version_check/run_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.out 2> run_lib_version_check/run_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.log && SUCCESS=1
    diff -q file.exp run_lib_version_check/run_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.out >/dev/null && SUCCESS=2
}


RUN_LIB_VERSION_CHECK_ALL(){
    rm -rf run_lib_version_check
    mkdir run_lib_version_check || die "Error: mkdir failed"
    for  CREATE_LIB_VERSION in $LIB_VERSIONS
        do
            for READ_LIB_VERSION in ${LIB_VERSIONS}
            do
                SUCCESS=0
                RUN_LIB_VERSION_CHECK
                echo -ne $SUCCESS"\t"
        done
        echo ""
    done

}


# Evaluate if any breaking changes were introduced in:
# 1. installing slow5lib
# 2. installing slow5tools
# 3. creating a BLOW5 file using each slow5tools version from a fast5 file
# 4. compiling, running and diffing a tiny example program (convert to pA) using each slow5lib version

# download all slow5libs
GET_LIB_ALL
# download all slow5tools
GET_SLOW5TOOLS_ALL
# create a BLOW5 file using each slow5tools version
CREATE_BLOW5_ALL
# compile the tiny example program and run using each slow5lib version
COMPILE_EXAMPLE_AND_RUN_ALL


# compatibility matrix of different slow5 file versions and slow5lib versions

# compile the test programs using each slow5lib version
COMPILE_PROGRAME_ALL
# Check the stability of each slow5 file version with each slow5lib version
echo "Checking the stability of each slow5 file version with each slow5lib version"
RUN_FILE_VERSION_CHECK_ALL > stability_format_matrix.txt
# Check the stability of each program version with each slow5lib version
echo "Check the stability of each program version with each slow5lib version"
RUN_LIB_VERSION_CHECK_ALL > stability_libversion_matrix.txt
echo "all done"