//sequentially loads a batch of reads from a SLOW5 file (reading fileds relavent to basecalling), process the batch (sum), and write output
//make zstd=1
//gcc -Wall -O2 -g -I include/ -o slow5_sequential_cxxpool sequential_cxxpool.cpp lib/libslow5.a  -lm -lz -lzstd -fopenmp
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured

#include <stdio.h>
#include <stdlib.h>
#include <slow5/slow5.h>
#include <omp.h>
#include <sys/time.h>
#include "cxxpool.h"
#include <inttypes.h>
#include <sys/resource.h>

// From minimap2
static inline long peakrss(void) {
    struct rusage r;
    getrusage(RUSAGE_SELF, &r);
#ifdef __linux__
    return r.ru_maxrss * 1024;
#else
    return r.ru_maxrss;
#endif

}

// From minimap2/misc
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

/* load a data batch from disk */
int load_raw_batch(char ***mem_a, size_t **bytes_a, slow5_file_t *sf, int batch_size) {

    char **mem = (char **)malloc(batch_size * sizeof(char *));
    size_t *bytes = (size_t *)malloc(batch_size * sizeof(size_t));

    int32_t i = 0;
    while (i < batch_size) {
        int ret  = slow5_get_next_bytes(&(mem[i]),&(bytes[i]), sf);

        if (ret < 0 ) {
            if (slow5_errno != SLOW5_ERR_EOF) {
                fprintf(stderr,"Error reading from SLOW5 file %d\n", slow5_errno);
                exit(EXIT_FAILURE);
            }
            else {
                break;
            }
        }
        else {
            i++;
        }
    }

    *mem_a = mem;
    *bytes_a = bytes;

    return i;
}

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
    uint64_t *sums = (uint64_t*)malloc(sizeof(uint64_t)*n);

    #pragma omp parallel for
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        uint64_t sum = 0;
        for(size_t j=0; j<rec->len_raw_signal; j++){
            sum += (rec->raw_signal[j]);
        }
        sums[i] = sum;
    }
    //fprintf(stderr,"batch processed with %d reads\n",n);

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
    //fprintf(stderr,"batch printed with %d reads\n",n);

    free(sums);
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        free(rec->raw_signal);
        free(rec->read_id);
    }
    free(rec_list);

}


int load_slow5_read(char **mem_records, size_t *mem_bytes, rec_t *rec_list, slow5_file_t *sp, int i){

    slow5_rec_t *srec = NULL;
    rec_t *rrec = &rec_list[i];
    const slow5_hdr_t* header = sp->header; //pointer to the SLOW5 header

    if(slow5_decode(&mem_records[i], &mem_bytes[i], &srec, sp)!=0){
        fprintf(stderr,"Error parsing the record %s",srec->read_id);
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
    free(mem_records[i]);

    return 0;
}

int read_and_process_slow5_file(const char *path, int num_thread, int batch_size, double *tot_time_p, double *disc_time_p){

    double tot_time = 0;
    double disc_time = 0;
    double t0 = 0;
    double t1 = 0;
    int ret = batch_size;
    int read_count = 0;

    print_header();

    omp_set_num_threads(num_thread);
    fprintf(stderr,"threads: %d\n", num_thread);
    fprintf(stderr,"batchsize: %d\n", batch_size);

    /**** Initialisation and opening of the file ***/
    t0 = realtime();

    slow5_file_t *sp = slow5_open(path,"r");
    if(sp==NULL){
       fprintf(stderr,"Error in opening file\n");
       perror("perr: ");
       exit(EXIT_FAILURE);
    }
    cxxpool::thread_pool pool{(size_t)num_thread};

    tot_time += realtime() - t0;
    /**** End of init ***/

    while(ret == batch_size){

        /**** Fetching a batch (disk loading, decompression, parsing in to memory arrays) ***/
        t0 = realtime();
        char **mem = NULL;
        size_t *bytes = NULL;
        ret = load_raw_batch(&mem, &bytes, sp, batch_size);
        t1= realtime() - t0;
        tot_time += t1;
        disc_time += t1;

        read_count += ret;

        t0 = realtime();
        rec_t *rec = (rec_t*)malloc(batch_size * sizeof(rec_t));
        std::vector<std::future<int>> futures;
        for (int i = 0; i < ret; ++i) {
            futures.push_back(pool.push(load_slow5_read, mem, bytes, rec, sp, i));
        }
        for (auto& v : futures) {
            v.get();
        }
//        #pragma omp parallel for
//        for(int i=0;i<ret;i++){
//            load_slow5_read(mem, bytes, rec, sp, i);
//        }
        tot_time += realtime() - t0;
        /**** Batch fetched ***/

        //fprintf(stderr,"batch loaded with %d reads\n",ret);

        //process and print (time not measured as we want to compare to the time it takes to read the file)
        process_read_batch(rec, ret);

        /**** Deinit ***/
        t0 = realtime();
        free(mem);
        free(bytes);
        tot_time += realtime() - t0;
        /**** End of Deinit***/

    }

    /**** Deinit ***/
    t0 = realtime();
    slow5_close(sp);
    tot_time += realtime() - t0;
    /**** End of Deinit***/

    *tot_time_p = tot_time;
    *disc_time_p = disc_time;
    return read_count;
}

int main(int argc, char *argv[]) {
    // Initial time
    double init_realtime = realtime();

    if(argc != 4) {
        fprintf(stderr, "Usage: %s reads.blow5 num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *path = argv[1];
    int batch_size = atoi(argv[3]);
    int num_thread = atoi(argv[2]);
    fprintf(stderr,"Using %d threads\n", num_thread);
    omp_set_num_threads(num_thread);

    int read_count = 0;
    double tot_time = 0;
    double disc_time = 0;
    read_count = read_and_process_slow5_file(path, num_thread, batch_size, &tot_time, &disc_time);
    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for disc reading %f\n",disc_time);
    fprintf(stderr,"Time for getting samples (disc+depress+parse) %f\n", tot_time);
    fprintf(stderr,"real time = %.3f sec | CPU time = %.3f sec | peak RAM = %.3f GB\n",
            realtime() - init_realtime, cputime(), peakrss() / 1024.0 / 1024.0 / 1024.0);
    return 0;
}
