//sequentially loads a batch of reads from a POD5 file (reading fileds relavent to basecalling), process the batch (sum), and write output
//make zstd=1
//gcc -Wall -O2 -g -I pod5_format/include -I cxxpool/src -o pod5_sequential sequential.cpp pod5_format/lib/libpod5_format.so -lm -lz -lzstd -lpthread -fopenmp
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured

#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <sys/time.h>
#include "pod5_format/c_api.h"
#include "cxxpool.h"
#include <inttypes.h>
#include <string.h>
#include <iostream>
#include <vector>
#include <sys/resource.h>

// 37 = number of bytes in UUID (32 hex digits + 4 dashes + null terminator)
const uint32_t POD5_READ_ID_LEN = 37;
constexpr size_t POD5_READ_ID_SIZE = 16;
using ReadID = std::array<uint8_t, POD5_READ_ID_SIZE>;

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
    int64_t run_acquisition_start_time;
    uint16_t sampling_rate;
    char* read_id;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
    uint64_t start_sample;
    double scale;
    double offset;
    int32_t read_number;
    uint8_t mux;
    uint16_t channel_number;
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
//    fprintf(stderr,"batch processed with %d reads\n",n);

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
        fprintf(stdout, "%" PRId64 "\t", rec->run_acquisition_start_time);

        fprintf(stdout, "\n");
    }
//    fprintf(stderr,"batch printed with %d reads\n",n);

    free(sums);
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        free(rec->raw_signal);
        free(rec->read_id);
    }
    free(rec_list);

}

int load_pod5_read(size_t row, Pod5ReadRecordBatch* batch, Pod5FileReader* file, rec_t *rec) {
    uint16_t read_table_version = 0;
    ReadBatchRowInfo_t read_data;
    if (pod5_get_read_batch_row_info_data(batch, row, READ_BATCH_ROW_INFO_VERSION, &read_data,
                                          &read_table_version) != POD5_OK) {
        fprintf(stderr, "Failed to get read %zu\n", row);
        return EXIT_FAILURE;
    }
    //Retrieve global information for the run
    RunInfoDictData_t* run_info_data;
    if (pod5_get_run_info(batch, read_data.run_info, &run_info_data) != POD5_OK) {
        fprintf(stderr, "Failed to get Run Info %zu %s\n", row, pod5_get_error_string());
        return EXIT_FAILURE;
    }
    rec->run_acquisition_start_time = run_info_data->acquisition_start_time_ms;
    rec->sampling_rate = run_info_data->sample_rate;
    char read_id_tmp[POD5_READ_ID_LEN];
    if (pod5_format_read_id(read_data.read_id, read_id_tmp) != POD5_OK) {
        fprintf(stderr, "Failed to format read id");
    }
    std::string read_id_str(read_id_tmp);
    rec->read_id = strdup(read_id_tmp);
    rec->len_raw_signal = read_data.num_samples;
    int16_t *samples = (int16_t*)malloc(sizeof(int16_t)*read_data.num_samples);
    if (pod5_get_read_complete_signal(file, batch, row, read_data.num_samples, samples) != POD5_OK) {
        fprintf(stderr, "Failed to get read %zu signal: %s\"\n", row, pod5_get_error_string());
        return EXIT_FAILURE;
    }
    rec->raw_signal = samples;
    rec->start_sample = read_data.start_sample;
    rec->scale = read_data.calibration_scale;
    rec->offset = read_data.calibration_offset;
    rec->read_number = read_data.read_number;
    rec->mux = read_data.well;
    rec->channel_number = read_data.channel;
    rec->run_id = strdup(run_info_data->acquisition_id);
    rec->flowcell_id = strdup(run_info_data->flow_cell_id);
    rec->position_id = strdup(run_info_data->sequencer_position);
    rec->experiment_id = strdup(run_info_data->experiment_name);
    if (pod5_free_run_info(run_info_data) != POD5_OK) {
        fprintf(stderr, "Failed to free run info\n");
        return EXIT_FAILURE;
    }
    return 0;
}

int read_and_process_pod5_file(const std::string& path, const char *rid_list_path, size_t num_thread, int batch_size, double* tot_time_p) {

    double tot_time = 0;
    double t0 = 0;
    int read_count = 0;

    print_header();

    //read id list
    FILE *fpr = fopen(rid_list_path,"r");
    if(fpr==NULL){
        fprintf(stderr,"Error in opening file %s for reading\n",rid_list_path);
        perror("perr: ");;
        exit(EXIT_FAILURE);
    }
    char tmp[1024];

    /**** Initialisation and opening of the file ***/
    t0 = realtime();

    pod5_init();
    Pod5FileReader_t* file = pod5_open_file(path.c_str());
    if (!file) {
        fprintf(stderr, "Failed to open file %s: %s\n", path.c_str(), pod5_get_error_string());
        exit(EXIT_FAILURE);
    }
    std::size_t batch_count = 0;
    if (pod5_get_read_batch_count(&batch_count, file) != POD5_OK) {
        fprintf(stderr, "Failed to query batch count: %s\n", pod5_get_error_string());
        exit(EXIT_FAILURE);
    }
    fprintf(stderr, "batch_count: %zu\n", batch_count);
    cxxpool::thread_pool pool{num_thread};

    tot_time += realtime() - t0;
    /**** End of init ***/

    while (1){

        // reading a batch of read IDs from the list
        std::vector<ReadID> read_ids;
        int i_count = 0;
        for(i_count=0; i_count < batch_size; i_count++){
            if (fscanf(fpr,"%s",tmp) < 1) {
                break;
            }
            uint8_t  arr[16] = {0};
            int ret = sscanf(tmp, "%2hhx%2hhx%2hhx%2hhx-%2hhx%hhx-%2hhx%2hhx-%2hhx%2hhx-%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx",
                             &arr[0], &arr[1], &arr[2], &arr[3], &arr[4], &arr[5], &arr[6], &arr[7],
                             &arr[8], &arr[9], &arr[10], &arr[11], &arr[12], &arr[13], &arr[14], &arr[15]);
            if(ret !=16){
                fprintf(stderr,"Parsing uuid failed. Return val %d\n",ret);
                exit(1);
            }
            // Store the read_id in the channel's list.
            ReadID read_id;
            memcpy(read_id.data(), arr, POD5_READ_ID_SIZE);
            read_ids.push_back(std::move(read_id));
        }

        if(i_count == 0) break;
        int ret = i_count;
        read_count += ret;

        /**** Plan traversal ***/
        t0 = realtime();

        std::vector<std::uint32_t> traversal_batch_counts(batch_count);
        std::vector<std::uint32_t> traversal_batch_rows(ret);
        std::size_t find_success_count = 0;
        std::vector<uint8_t> read_id_array(POD5_READ_ID_SIZE * read_ids.size());
        for (size_t i = 0; i < read_ids.size(); i++) {
            memcpy(read_id_array.data() + POD5_READ_ID_SIZE * i, read_ids[i].data(), POD5_READ_ID_SIZE);
        }
        pod5_error_t err = pod5_plan_traversal(file, read_id_array.data(), read_ids.size(),
                                               traversal_batch_counts.data(),
                                               traversal_batch_rows.data(), &find_success_count);
        if (err != POD5_OK) {
            fprintf(stderr,"Couldn't create plan for %s with reads %zu\n", path.c_str(), read_ids.size());
            return EXIT_FAILURE;
        }
        if (find_success_count != read_ids.size()) {
            fprintf(stderr,"Reads found by plan %zu, reads in input %zu\n", find_success_count, read_ids.size());
            fprintf(stderr,"Plan traveral didn't yield correct number of reads\n");
            return EXIT_FAILURE;
        }

        tot_time += realtime() - t0;
        /**** Plan traversal done ***/

        uint32_t row_offset = 0;
        // pod5 batching
        for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {

            /**** Fetching a batch ***/
            t0 = realtime();

            Pod5ReadRecordBatch_t* batch = nullptr;
            if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
                fprintf(stderr, "Failed to get batch: %s\n", pod5_get_error_string());
                exit(EXIT_FAILURE);
            }
            int mini_batch_size = traversal_batch_counts[batch_index];
            rec_t *rec = (rec_t*)malloc(mini_batch_size * sizeof(rec_t));
            std::vector<std::future<int>> futures;
            for (std::size_t row_idx = 0; row_idx < traversal_batch_counts[batch_index]; row_idx++) {
                uint32_t row = traversal_batch_rows[row_idx + row_offset];
                futures.push_back(pool.push(load_pod5_read,row, batch, file, &rec[row_idx + row_offset]));
            }
            for (auto& v : futures) {
                v.get();
            }

            tot_time += realtime() - t0;
            /**** Batch fetched ***/

//        fprintf(stderr,"batch loaded with %zu reads\n", batch_row_count);

            //process and print (time not measured as we want to compare to the time it takes to read the file)
            process_read_batch(rec, ret);

            /**** Deinit ***/
            t0 = realtime();
            if (pod5_free_read_batch(batch) != POD5_OK) {
                fprintf(stderr, "Failed to release batch\n");
                exit(EXIT_FAILURE);
            }
            tot_time += realtime() - t0;
            /**** End of Deinit***/

            row_offset += traversal_batch_counts[batch_index];
        }

        if(ret<batch_size){ //this indicates nothing left to read
            break;
        }

    }

    /**** Deinit ***/
    t0 = realtime();
    if (pod5_close_and_free_reader(file) != POD5_OK) {
        fprintf(stderr, "Failed to close and free POD5 reader\n");
        exit(EXIT_FAILURE);
    }
    tot_time += realtime() - t0;
    /**** End of Deinit***/

    fclose(fpr);

    *tot_time_p = tot_time;
    return read_count;
}

int main(int argc, char *argv[]) {
    // Initial time
    double init_realtime = realtime();

    if(argc != 5) {
        fprintf(stderr, "Usage: %s reads.pod5 rid_list.txt num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *path = argv[1];
    const char *rid_list_path = argv[2];
    int num_thread = atoi(argv[3]);
    int batch_size = atoi(argv[4]);
    fprintf(stderr,"Using %d threads\n", num_thread);
    omp_set_num_threads(num_thread);

    int read_count = 0;
    double tot_time = 0;
    read_count = read_and_process_pod5_file(path, rid_list_path, num_thread, batch_size, &tot_time);
    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for getting samples (disc+depress+parse) %f\n", tot_time);
    fprintf(stderr,"real time = %.3f sec | CPU time = %.3f sec | peak RAM = %.3f GB\n",
            realtime() - init_realtime, cputime(), peakrss() / 1024.0 / 1024.0 / 1024.0);
    return 0;
}
