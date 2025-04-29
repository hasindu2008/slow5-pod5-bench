#!/bin/bash

FILE_VERSIONS="v0  v1  v2  v3"
LIB_VERSIONS="0.0.1  0.0.3  0.0.4  0.0.5  0.0.9  0.0.11  0.0.12  0.0.13  0.0.14  0.0.15  0.0.16  0.0.17  0.0.19  0.0.20  0.0.23  0.0.31  0.0.32  0.0.41  0.0.43  0.1.0  0.1.4  0.1.5  0.1.8  0.1.10  0.1.11  0.1.12  0.1.13  0.1.15  0.1.16  0.1.19  0.1.20  0.1.21  0.2.0  0.2.2  0.2.3  0.2.4  0.3.0  0.3.1  0.3.2  0.3.6  0.3.10  0.3.11  0.3.12  0.3.15  0.3.21  0.3.23"

### inotifywait -r -m .  > a.txt
### cat a.txt  | grep "arrow\|OPEN pod5" | uniq  > libversion.inotify.txt

### inotifywait -r -m .  > b.txt
### cat b.txt  | grep "arrow\|OPEN pod5" | uniq  > file.inotify.txt


GET_CONVERSIONS_LIBVERSIONS(){

for  CREATE_LIB_VERSION in $LIB_VERSIONS
    do
        for READ_LIB_VERSION in ${LIB_VERSIONS}
        do
            CONVERT=0
            VAL=$(grep -w "pod5_read_${READ_LIB_VERSION}" -A 2 libversion.inotify.txt | grep -w "pod5-${CREATE_LIB_VERSION}.pod5" -A 1 | tail -1 | awk '{print $NF}')
            if echo "$VAL" | grep -q "arrow"
            then
                CONVERT=1
            fi
            echo -ne $CONVERT"\t"
        done
    echo ""
done

}

GET_CONVERSIONS_FILEVERSIONS(){
    for  CREATE_LIB_VERSION in $LIB_VERSIONS
    do
        for READ_LIB_VERSION in ${LIB_VERSIONS}
        do
            CONVERT=0
            VAL=$(grep -w "pod5_read_${READ_LIB_VERSION}" -A 2 file.inotify.txt | grep -w "pod5-${CREATE_LIB_VERSION}.pod5" -A 1 | tail -1 | awk '{print $NF}')
            if echo "$VAL" | grep -q "arrow"
            then
                CONVERT=1
            fi
            echo -ne $CONVERT"\t"
        done
    echo ""
    done
}

GET_CONVERSIONS_LIBVERSIONS > conversions_libversion.txt
GET_CONVERSIONS_FILEVERSIONS > conversions_fileversion.txt