#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

//https://stackoverflow.com/questions/61081664/parsintg-uuid-using-sscanf

int main(int argc, char **argv){
    if(argc != 2 ){
        fprintf(stderr,"Usage: %s uuid-string\n",argv[0]);
        exit(1);
    }
    const char *uuidstr = argv[1];
    uint8_t  arr[16] = {0};
    int ret = sscanf(uuidstr, "%2hhx%2hhx%2hhx%2hhx-%2hhx%hhx-%2hhx%2hhx-%2hhx%2hhx-%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx",
                     &arr[0], &arr[1], &arr[2], &arr[3], &arr[4], &arr[5], &arr[6], &arr[7],
                     &arr[8], &arr[9], &arr[10], &arr[11], &arr[12], &arr[13], &arr[14], &arr[15]);
    if(ret !=16){
        fprintf(stderr,"Parsing uuid failed. Return val %d\n",ret);
        exit(1);
    }

    for(int i=0; i<16; i++){
        printf("%02hhx",arr[i]);
    }
    printf("\n");

    return 0;
}