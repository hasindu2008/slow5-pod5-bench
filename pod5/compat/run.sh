#!/bin/bash

FILE_VERSIONS="v0  v1  v2  v3"
LIB_VERSIONS="0.0.1  0.0.3  0.0.4  0.0.5  0.0.9  0.0.11  0.0.12  0.0.13  0.0.14  0.0.15  0.0.16  0.0.17  0.0.19  0.0.20  0.0.23  0.0.31  0.0.32  0.0.41  0.0.43  0.1.0  0.1.4  0.1.5  0.1.8  0.1.10  0.1.11  0.1.12  0.1.13  0.1.15  0.1.16  0.1.19  0.1.20  0.1.21  0.2.0  0.2.2  0.2.3  0.2.4  0.3.0  0.3.1  0.3.2  0.3.6  0.3.10  0.3.11  0.3.12  0.3.15  0.3.21  0.3.23"

#  cp pod5/pod5-0.0.23.pod5 v0.pod5
#  cp pod5/pod5-0.0.31.pod5 v1.pod5
#  cp pod5/pod5-0.0.32.pod5 v2.pod5
#  cp pod5/pod5-0.1.0.pod5 v3.pod5

die () {
    echo "$1" >&2
    exit 1
}

# Function to compare semantic versions //thanks chatgpt
# Returns 0 if v1 == v2, 1 if v1 > v2, 2 if v1 < v2
compare_versions() {
    local v1=(${1//./ })
    local v2=(${2//./ })

    for i in 0 1 2; do
        [[ -z ${v1[i]} ]] && v1[i]=0
        [[ -z ${v2[i]} ]] && v2[i]=0
        if (( 10#${v1[i]} > 10#${v2[i]} )); then
            return 1
        elif (( 10#${v1[i]} < 10#${v2[i]} )); then
            return 2
        fi
    done
    return 0
}

GET_LIB(){

    compare_versions ${LIB_VERSION} 0.0.14
    res=$?
    if [ $res -eq 2 ]; then
        wget --no-verbose https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr-file-format-${LIB_VERSION}-linux-x64.tar.gz || die "Error: wget failed"
        mkdir lib_pod5-${LIB_VERSION} || die "Error: mkdir failed"
        tar xf mkr-file-format-${LIB_VERSION}-linux-x64.tar.gz -C lib_pod5-${LIB_VERSION} || die "Error: tar failed"
        echo "GOT"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.43
    res=$?
    if [ $res -eq 2 ]; then
        wget --no-verbose https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/pod5-file-format-${LIB_VERSION}-linux-x64.tar.gz || die "Error: wget failed"
        mkdir lib_pod5-${LIB_VERSION} || die "Error: mkdir failed"
        tar xf  pod5-file-format-${LIB_VERSION}-linux-x64.tar.gz -C lib_pod5-${LIB_VERSION} || die "Error: tar failed"
        echo "GOT"
        return
    fi

    if  [ ${LIB_VERSION} = "0.3.0" ] || [ ${LIB_VERSION} = "0.3.1" ] ; then
        echo "NO binary"
        return
    fi

    wget --no-verbose https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/lib_pod5-${LIB_VERSION}-linux-x64.tar.gz || die "Error: wget failed"
    mkdir lib_pod5-${LIB_VERSION} || die "Error: mkdir failed"
    tar xf  lib_pod5-${LIB_VERSION}-linux-x64.tar.gz -C lib_pod5-${LIB_VERSION} || die "Error: tar failed"
    echo "GOT"

}

GET_LIB_ALL(){
    rm -rf pod5lib
    mkdir pod5lib || die "Error: mkdir failed"
    cd pod5lib || die "Error: cd failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "getting pod5lib version ${LIB_VERSION}"
        GET_LIB &> get_lib_${LIB_VERSION}.log
    done
    cd ..
}


GET_POD5TOOLS(){
    python3.10 -m venv vnenv_${LIB_VERSION} || die "Error: venv failed"
    source vnenv_${LIB_VERSION}/bin/activate || die "Error: source failed"
    pip3 install --upgrade pip || die "Error: pip failed"

    # <= 0.0.4
    compare_versions ${LIB_VERSION} 0.0.5
    res=$?
    if [ $res -eq 2 ]; then
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format-${LIB_VERSION}-py2.py3-none-any.whl || die "Error: pip failed"
        pip3 install "numpy<=1.39" || die "Error: pip failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    # 0.0.5
    compare_versions ${LIB_VERSION} 0.0.6
    res=$?
    if [ $res -eq 2 ]; then
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format-${LIB_VERSION}-cp310-cp310-linux_x86_64.whl || die "Error: pip failed"
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format_tools-0.0.1-py3-none-any.whl || die "Error: pip failed"
        pip3 install "numpy<=1.39" || die "Error: pip failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    # 0.0.9
    compare_versions ${LIB_VERSION} 0.0.11
    res=$?
    if [ $res -eq 2 ]; then
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format-${LIB_VERSION}-cp310-cp310-linux_x86_64.whl || die "Error: pip failed"
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format_tools-${LIB_VERSION}-py3-none-any.whl || die "Error: pip failed"
        pip3 install "numpy<=1.39" || die "Error: pip failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.14
    res=$?
    if [ $res -eq 2 ]; then
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format-${LIB_VERSION}-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl || die "Error: pip failed"
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/mkr_format_tools-${LIB_VERSION}-py3-none-any.whl || die "Error: pip failed"
        pip3 install "numpy<=1.39" || die "Error: pip failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.43
    res=$?
    if [ $res -eq 2 ]; then
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/pod5_format-${LIB_VERSION}-cp310-cp310-manylinux_2_17_x86_64.manylinux2014_x86_64.whl || die "Error: pip failed"
        pip3 install https://github.com/nanoporetech/pod5-file-format/releases/download/${LIB_VERSION}/pod5_format_tools-${LIB_VERSION}-py3-none-any.whl || die "Error: pip failed"
        pip3 install "numpy<=1.39" || die "Error: pip failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    if [ ${LIB_VERSION} = "0.1.8" ] || [ ${LIB_VERSION} = "0.1.8" ] ; then
        echo "NO binary"
        deactivate || die "Error: deactivate failed"
        return
    fi

    pip3 install pod5==${LIB_VERSION} || die "Error: pip failed"
    pod5 --version || pip3 install "numpy<=1.39" || die "Error: pip failed" # find where numpy new is needed
    pod5 --version > vnenv_${LIB_VERSION}/version.log || die "Error: pod5 failed"

    deactivate || die "Error: deactivate failed"
}

GET_POD5TOOLS_ALL(){
    rm -rf pod5tools
    mkdir pod5tools || die "Error: mkdir failed"
    cd pod5tools || die "Error: cd failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "pod5tools version ${LIB_VERSION}"
        GET_POD5TOOLS &> get_pod5tools_${LIB_VERSION}.log
    done
    cd ..
}

COMPILE_EXAMPLE_AND_RUN(){

    if  [ ${LIB_VERSION} = "0.0.5" ] || [ ${LIB_VERSION} = "0.0.9" ]; then
        echo "No BINARY"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.14
    res=$?
    if [ $res -eq 2 ]; then
        set -x
        g++ pod5_example_0.0.1.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -lz -o example/pod5_read_${LIB_VERSION} -I./ -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libmkr_format.so  || die "Error: gcc failed"
        example/pod5_read_${LIB_VERSION} pod5/pod5-${LIB_VERSION}.pod5 > example/example_lib_${LIB_VERSION}.out 2> example/example_lib_${LIB_VERSION}.log || die "Error: example failed"
        set +x
        diff -q example.exp example/example_lib_${LIB_VERSION}.out  || die "Error: diff failed"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.41
    res=$?
    if [ $res -eq 2 ]; then
        set -x
        g++ pod5_example_0.0.14.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -lz -o example/pod5_read_${LIB_VERSION} -I./ -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libpod5_format.so  || die "Error: gcc failed"
        example/pod5_read_${LIB_VERSION} pod5/pod5-${LIB_VERSION}.pod5 > example/example_lib_${LIB_VERSION}.out 2> example/example_lib_${LIB_VERSION}.log || die "Error: example failed"
        set +x
        diff -q example.exp example/example_lib_${LIB_VERSION}.out  || die "Error: diff failed"
        return
    fi

    if  [ ${LIB_VERSION} = "0.3.0" ] || [ ${LIB_VERSION} = "0.3.1" ] ; then
        echo "NO binary"
        return
    fi

    set -x
    g++ pod5_example_0.0.41.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -lz -o example/pod5_read_${LIB_VERSION} -I./ -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libpod5_format.so  || die "Error: gcc failed"
    set +x
    if [ ${LIB_VERSION} = "0.1.8" ]; then
        echo "NO binary"
        return
    fi
    set -x
    example/pod5_read_${LIB_VERSION} pod5/pod5-${LIB_VERSION}.pod5 > example/example_lib_${LIB_VERSION}.out 2> example/example_lib_${LIB_VERSION}.log || die "Error: example failed"
    set +x
    diff -q example.exp example/example_lib_${LIB_VERSION}.out  || die "Error: diff failed"
    return

}

COMPILE_EXAMPLE_AND_RUN_ALL(){
    rm -rf example/
    mkdir example || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Compiling example and running version ${LIB_VERSION}"
        COMPILE_EXAMPLE_AND_RUN &> example/compile_example_${LIB_VERSION}.log
    done
}


COMPILE_PROGRAME(){

    if  [ ${LIB_VERSION} = "0.0.5" ] || [ ${LIB_VERSION} = "0.0.9" ]; then
        echo "No BINARY"
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.14
    res=$?
    if [ $res -eq 2 ]; then
        set -x
        g++ pod5_read_0.0.1.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -I./ -lz -o program/pod5_read_${LIB_VERSION} -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libmkr_format.so  || die "Error: gcc failed"
        set +x
        return
    fi

    compare_versions ${LIB_VERSION} 0.0.41
    res=$?
    if [ $res -eq 2 ]; then
        set -x
        g++ pod5_read_0.0.14.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -lz -o program/pod5_read_${LIB_VERSION} -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libpod5_format.so  || die "Error: gcc failed"
        set +x
        return
    fi

    if  [ ${LIB_VERSION} = "0.3.0" ] || [ ${LIB_VERSION} = "0.3.1" ] ; then
        echo "NO binary"
        return
    fi

    # from 0.0.41 onwards
    set -x
    g++ pod5_read_0.0.41.cpp -Wl,-rpath,pod5lib/lib_pod5-${LIB_VERSION}/lib/ -lz -o program/pod5_read_${LIB_VERSION} -I pod5lib/lib_pod5-${LIB_VERSION}/include/ pod5lib/lib_pod5-${LIB_VERSION}/lib/libpod5_format.so  || die "Error: gcc failed"
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


CREATE_POD5(){
    source pod5tools/vnenv_${LIB_VERSION}/bin/activate || die "Error: source failed"

    #<0.0.14
    compare_versions ${LIB_VERSION} 0.0.14
    res=$?
    if [ $res -eq 2 ]; then
        mkr-convert-fast5 file.fast5 pod5/pod5-${LIB_VERSION}-tmp || die "Error: pod5tools failed"
        mv pod5/pod5-${LIB_VERSION}-tmp/output.mkr  pod5/pod5-${LIB_VERSION}.pod5 || die "Error: mv failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    #0.0.14 to <0.0.43
    compare_versions ${LIB_VERSION} 0.0.43
    res=$?
    if [ $res -eq 2 ]; then
        pod5-convert-fast5 file.fast5 pod5/pod5-${LIB_VERSION}-tmp || die "Error: pod5tools failed"
        mv pod5/pod5-${LIB_VERSION}-tmp/output.pod5  pod5/pod5-${LIB_VERSION}.pod5 || die "Error: mv failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    #0.0.43
    compare_versions ${LIB_VERSION} 0.1.0
    res=$?
    if [ $res -eq 2 ]; then
        pod5-convert-fast5 file.fast5 pod5/pod5-${LIB_VERSION}.pod5 || die "Error: pod5tools failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    if [ ${LIB_VERSION} = "0.1.8" ] || [ ${LIB_VERSION} = "0.1.8" ] ; then
        echo "NO binary"
        deactivate || die "Error: deactivate failed"
        return
    fi

    #0.1.0 to onwards
    compare_versions ${LIB_VERSION} 0.1.12
    res=$?
    if [ $res -eq 2 ]; then
        pod5 convert fast5 file.fast5 pod5/pod5-${LIB_VERSION}.pod5 || die "Error: pod5tools failed"
        deactivate || die "Error: deactivate failed"
        return
    fi

    pod5 convert fast5 file.fast5 -o pod5/pod5-${LIB_VERSION}.pod5 || die "Error: pod5tools failed"
    deactivate || die "Error: deactivate failed"
}

CREATE_POD5_ALL(){
    rm -rf pod5
    mkdir pod5 || die "Error: mkdir failed"
    for LIB_VERSION in ${LIB_VERSIONS}
    do
        echo "Creating pod5 version ${LIB_VERSION}"
        CREATE_POD5 &> pod5/create_pod5_${LIB_VERSION}.log
    done
}


RUN_FILE_VERSION_CHECK(){
    program/pod5_read_${LIB_VERSION} ${FILE_VERSION}.pod5 > run_file_version_check/run_${FILE_VERSION}_lib_${LIB_VERSION}.out 2> run_file_version_check/run_${FILE_VERSION}_lib_${LIB_VERSION}.log && SUCCESS=1
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


RUN_LIB_VERSION_CHECK(){

    program/pod5_read_${READ_LIB_VERSION} pod5/pod5-${CREATE_LIB_VERSION}.pod5 > run_lib_version_check/run_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.out 2> run_lib_version_check/run_${CREATE_LIB_VERSION}_read_${READ_LIB_VERSION}.log && SUCCESS=1
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
# 1. installing pod5lib binary
# 2. installing pod5tools
# 3. creating a pod5 file using each pod5 version from a fast5 file
# 4. compiling, running and diffing a tiny example program (getting all read ids) using each pod5 version

# Getting all the pod5 library versions
GET_LIB_ALL
# Getting all the pod5tools versions
GET_POD5TOOLS_ALL
# Creating all the pod5 files from different pod5tools versions
CREATE_POD5_ALL
# compile the tiny example program and run using each pod5 version
COMPILE_EXAMPLE_AND_RUN_ALL

# # compatibility matrix of different pod5 file versions and pod5 library versions

# # compile the test program using each pod5 version
COMPILE_PROGRAME_ALL
echo "Checking the stability of each pod5 file version with each pod5lib version"
RUN_FILE_VERSION_CHECK_ALL > stability_format_matrix.txt
# # Check the stability of each program version with each pod5lib version
echo "Check the stability of each program version with each pod5lib version"
RUN_LIB_VERSION_CHECK_ALL > stability_libversion_matrix.txt
echo "all done"