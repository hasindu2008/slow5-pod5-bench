//loads a batch of reads (fileds relavent to basecalling) as specified through a list of readIDs, process the batch (sum), and write output
//make zstd=1
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured

// to generate read id list in genomics coordinate order: samtools view reads.sorted.bam | awk '{print $1}' > rid.txt

#include <stdio.h>
#include <stdlib.h>
#include <slow5/slow5.h>
#include <omp.h>
#include <sys/time.h>
#include <sys/resource.h>

static inline long peakrss(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
#ifdef __linux__
    return r.ru_maxrss * 1024;
#else
    return r.ru_maxrss;
#endif
}

static inline double cputime(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
    return r.ru_utime.tv_sec + r.ru_stime.tv_sec +
           1e-6 * (r.ru_utime.tv_usec + r.ru_stime.tv_usec);
}

static inline double realtime(void) {
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);
    return tp.tv_sec + tp.tv_usec * 1e-6;
}

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

void process_read_batch(rec_t *rec_list, int n){
    uint64_t *sums = malloc(sizeof(uint64_t)*n);

    #pragma omp parallel for
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        uint64_t sum = 0;
        for(int j=0; j<rec->len_raw_signal; j++){
            sum += (rec->raw_signal[j]);
        }
        sums[i] = sum;
    }
    fprintf(stderr,"batch processed with %d reads\n",n);

    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];

        fprintf(stdout, "%s\t", rec->read_id);
        fprintf(stdout, "%.2f\t", rec->scale);
        fprintf(stdout, "%.2f\t", rec->offset);
        fprintf(stdout, "%" PRIu16 "\t", rec->sampling_rate);
        fprintf(stdout, "%" PRIu64 "\t", rec->len_raw_signal);
        fprintf(stdout,"%"  PRIu64 "\t",sums[i]);

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
    fprintf(stderr,"batch printed with %d reads\n",n);

    free(sums);
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        free(rec->raw_signal);
        free(rec->read_id);
    }
    free(rec_list);

}


int load_slow5_read(rec_t *rec_list, slow5_file_t *sp, char **rid_list, int i){

    slow5_rec_t *srec = NULL;
    rec_t *rrec = &rec_list[i];
    const slow5_hdr_t* header = sp->header; //pointer to the SLOW5 header


    if(slow5_get(rid_list[i], &srec, sp) < 0){
        fprintf(stderr,"Error fetching the read %s",rid_list[i]);
        exit(EXIT_FAILURE);
    }

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

    srec->raw_signal = NULL;
    srec->read_id = NULL;

    slow5_rec_free(srec);

    return 0;
}

int read_and_process_slow5_file(const char *path, const char *rid_list_path, int num_thread, int batch_size, double *tot_time_p){

    double tot_time = 0;
    double t0 = 0;
    int ret = batch_size;
    int read_count = 0;

    print_header();

    omp_set_num_threads(num_thread);
    fprintf(stderr,"threads: %d\n", num_thread);
    fprintf(stderr,"batchsize: %d\n", batch_size);

    //read id list
    FILE *fpr = fopen(rid_list_path,"r");
    if(fpr==NULL){
        fprintf(stderr,"Error in opening file %s for reading\n",rid_list_path);
        perror("perr: ");;
        exit(EXIT_FAILURE);
    }

    char **rid = malloc(sizeof(char*)*batch_size);
    char tmp[1024];

    /**** Initialisation and opening of the file ***/
    t0 = realtime();

    slow5_file_t *sp = slow5_open(path,"r");
    if(sp==NULL){
       fprintf(stderr,"Error in opening file\n");
       perror("perr: ");
       exit(EXIT_FAILURE);
    }

    ret = slow5_idx_load(sp);
    if(ret<0){
        fprintf(stderr,"Error in loading index\n");
        exit(EXIT_FAILURE);
    }

    tot_time += realtime() - t0;
    /**** End of init ***/

    while(1){

        // reading a batch of read IDs from the list
        int i=0;
        for(i=0; i<batch_size; i++){
            if (fscanf(fpr,"%s",tmp) < 1) {
                break;
            }
            rid[i] = strdup(tmp);
        }
        if(i==0) break;
        int ret = i;
        read_count += ret;

        /**** Fetching a batch (disk loading, decompression, parsing in to memory arrays) ***/

        t0 = realtime();
        rec_t *rec = (rec_t*)malloc(batch_size * sizeof(rec_t));
        #pragma omp parallel for
        for(int i=0;i<ret;i++){
            load_slow5_read(rec, sp, rid, i);
        }
        tot_time += realtime() - t0;
        /**** Batch fetched ***/

        fprintf(stderr,"batch loaded with %d reads\n",ret);

        //process and print (time not measured as we want to compare to the time it takes to read the file)
        process_read_batch(rec, ret);

        // free the read ids list (time not measured as this is the readID list)
        for(int i=0; i<ret; i++){
            free(rid[i]);
        }

        if(ret<batch_size){ //this indicates nothing left to read
            break;
        }

    }

    /**** Deinit ***/
    t0 = realtime();
    slow5_idx_unload(sp);
    slow5_close(sp);
    tot_time += realtime() - t0;
    /**** End of Deinit***/

    fclose(fpr);
    free(rid);

    *tot_time_p = tot_time;
    return read_count;

}


int main(int argc, char *argv[]) {
    double init_realtime = realtime();
    if(argc != 5) {
        fprintf(stderr, "Usage: %s reads.blow5 rid_list.txt num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *path = argv[1];
    const char *rid_list_path = argv[2];
    int batch_size = atoi(argv[4]);
    int num_thread = atoi(argv[3]);

    int read_count = 0;
    double tot_time = 0;

    read_count = read_and_process_slow5_file(path, rid_list_path, num_thread, batch_size, &tot_time);
    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for getting samples (disc+depress+parse) %f\n", tot_time);
    double cpu_time = cputime();
    double real_time = realtime() - init_realtime;
    fprintf(stderr,"real time = %.3f sec | CPU time = %.3f sec | peak RAM = %.3f GB | CPU Usage = %.1f%%\n",
            real_time, cpu_time, peakrss() / 1024.0 / 1024.0 / 1024.0, cpu_time/(real_time*num_thread)*100);
    return 0;
}
