#include <stdio.h>
#include <stdlib.h>
#include <slow5/slow5.h>

typedef struct {
    char* read_id;
    double offset;
    double scale;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
} rec_t;


void process_read(rec_t *rec){

    uint64_t sum = 0;
    for(int j=0; j<rec->len_raw_signal; j++){
        sum += ((rec->raw_signal[j] + rec->offset) * rec->scale);
    }
    fprintf(stdout,"%s\t%ld\n",rec->read_id,sum);

}

int load_slow5_read(rec_t *rrec, slow5_rec_t *srec, slow5_file_t *sp){

    rrec->read_id = srec->read_id;
    rrec->len_raw_signal = srec->len_raw_signal;
    rrec->raw_signal = srec->raw_signal;
    rrec->scale = srec->range/ srec->digitisation;
    rrec->offset = srec->offset;

    return 0;
}

int read_and_process_slow5_file(const char *path){

    int read_count = 0;

    /**** Initialisation and opening of the file ***/

    slow5_file_t *sp = slow5_open(path,"r");
    if(sp==NULL){
       fprintf(stderr,"Error in opening file\n");
       perror("perr: ");
       exit(EXIT_FAILURE);
    }
    slow5_rec_t *srec = NULL; //slow5 record to be read
    int ret=0; //for return value

    /**** End of init ***/

    //iterate through the file until end
    while((ret = slow5_get_next(&srec,sp)) >= 0){
        rec_t rrec;
        load_slow5_read(&rrec, srec, sp);
        process_read(&rrec);
        read_count++;
    }

    if(ret != SLOW5_ERR_EOF){  //check if proper end of file has been reached
        fprintf(stderr,"Error in slow5_get_next. Error code %d\n",ret);
        exit(EXIT_FAILURE);
    }

    /**** Deinit ***/
    slow5_rec_free(srec);
    slow5_close(sp);
    /**** End of Deinit***/

    return read_count;
}



int main(int argc, char *argv[]) {

    if(argc != 2) {
        fprintf(stderr, "Usage: %s reads.blow5\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *path = argv[1];

    int read_count = 0;
    read_count = read_and_process_slow5_file(path);
    fprintf(stderr,"Reads: %d\n",read_count);
    return 0;
}