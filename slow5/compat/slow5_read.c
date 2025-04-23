#include <stdio.h>
#include <stdlib.h>
#include <slow5/slow5.h>

typedef struct {
    const char *run_acquisition_start_time; //can we convert to match pod5
    uint16_t sampling_rate; //converted to match pod5
    char* read_id;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
    uint64_t start_sample;
    double scale; //converted to match pod5
    double offset;
    int32_t read_number; //converted to match pod5
    uint8_t mux;
    uint16_t channel_number; //converted to match pod5
    const char* run_id;
    const char* flowcell_id;
    const char* position_id;
    const char* experiment_id;
} rec_t;


void print_header(){

    fprintf(stdout, "read_id\t");
    fprintf(stdout, "scale\t");
    fprintf(stdout, "offset\t");
    fprintf(stdout, "sampling_rate\t");
    fprintf(stdout, "len_raw_signal\t");
    fprintf(stdout, "signal_sums\t");

    fprintf(stdout, "channel_number\t");
    fprintf(stdout, "read_number\t");
    fprintf(stdout, "mux\t");
    fprintf(stdout, "start_sample\t");

    fprintf(stdout, "run_id\t");
    fprintf(stdout, "experiment_id\t");
    fprintf(stdout, "flowcell_id\t");
    fprintf(stdout, "position_id\t");
    fprintf(stdout, "run_acquisition_start_time\t");

    fprintf(stdout, "\n");
}

void process_read(rec_t *rec){

    uint64_t sum = 0;
    for(int j=0; j<rec->len_raw_signal; j++){
        sum += (rec->raw_signal[j]);
    }

    fprintf(stdout, "%s\t", rec->read_id);
    fprintf(stdout, "%.2f\t", rec->scale);
    fprintf(stdout, "%.2f\t", rec->offset);
    fprintf(stdout, "%" PRIu16 "\t", rec->sampling_rate);
    fprintf(stdout, "%" PRIu64 "\t", rec->len_raw_signal);
    fprintf(stdout,"%"  PRIu64 "\t",sum);

    fprintf(stdout, "%" PRIu16 "\t", rec->channel_number);
    fprintf(stdout, "%" PRIu32 "\t",rec->read_number);
    fprintf(stdout, "%" PRIu8 "\t", rec->mux);
    fprintf(stdout, "%" PRIu64 "\t", rec->start_sample);

    fprintf(stdout, "%s\t", rec->run_id == NULL ? "." : rec->run_id);
    fprintf(stdout, "%s\t", rec->experiment_id == NULL ? "." : rec->experiment_id);
    fprintf(stdout, "%s\t", rec->flowcell_id == NULL ? "." : rec->flowcell_id);
    fprintf(stdout, "%s\t", rec->position_id == NULL ? "." : rec->position_id);
    fprintf(stdout, "%s\t", rec->run_acquisition_start_time == NULL ? "." : rec->run_acquisition_start_time);

    fprintf(stdout, "\n");

}

int load_slow5_read(rec_t *rrec, slow5_rec_t *srec, slow5_file_t *sp){

    const slow5_hdr_t* header = sp->header; //pointer to the SLOW5 header

    uint32_t read_group = srec->read_group;
    rrec->run_acquisition_start_time = slow5_hdr_get("acquisition_start_time", read_group, header);
    rrec->sampling_rate = srec->sampling_rate;
    rrec->read_id = srec->read_id;
    rrec->len_raw_signal = srec->len_raw_signal;
    rrec->raw_signal = srec->raw_signal;
    rrec->start_sample =  slow5_aux_get_uint64(srec, "start_time", NULL);
    rrec->scale = srec->range/ srec->digitisation;
    rrec->offset = srec->offset;
    rrec->read_number = slow5_aux_get_int32(srec, "read_number", NULL);
    rrec->mux = slow5_aux_get_uint8(srec, "start_mux", NULL);
    rrec->channel_number = atoi(slow5_aux_get_string(srec, "channel_number", NULL, NULL));
    rrec->run_id = slow5_hdr_get("run_id", read_group, header);
    rrec->flowcell_id = slow5_hdr_get("flow_cell_id", read_group, header);
    rrec->position_id = slow5_hdr_get("sequencer_position", read_group, header);
    rrec->experiment_id = slow5_hdr_get("experiment_name", read_group, header);

    return 0;
}

int read_and_process_slow5_file(const char *path){

    int read_count = 0;

    print_header();

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