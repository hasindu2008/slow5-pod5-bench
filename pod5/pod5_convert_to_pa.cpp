//g++-9  -Wall -O2 -I pod5_format/include/ -o pod5_convert_to_pa pod5_convert_to_pa.c pod5_format/lib64/libpod5_format.a  pod5_format/lib64/libarrow.a pod5_format/lib64/libboost_filesystem.a -lm -lz -lzstd -fopenmp
//loads a batch of reads (signal+information needed for pA conversion) from file, process the batch (convert to pA and sum), and write output
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <iostream>
#include "pod5_format/c_api.h"
#include "cxxpool.h"
#include <inttypes.h>
#include <omp.h>

// 37 = number of bytes in UUID (32 hex digits + 4 dashes + null terminator)
const uint32_t POD5_READ_ID_LEN = 37;

static inline double realtime(void) {
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);
    return tp.tv_sec + tp.tv_usec * 1e-6;
}

typedef struct {
    int64_t run_acquisition_start_time_ms;
    uint16_t sampling_rate;
    char* read_id;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
    uint64_t start_sample;
    double scale;
    double offset;
    uint32_t read_number;
    uint8_t mux;
    uint16_t channel_number;
    char* run_id;
    char* flowcell_id;
    char* position_id;
    char* experiment_id;
} rec_t;

unsigned int djb2Hash(const char* str) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++)) {
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }
    return hash;
}

unsigned int compute_hash(const uint64_t sum, const rec_t *rec) {
    unsigned int hash = 0;
    hash = (hash * 31) + (unsigned int)rec->run_acquisition_start_time_ms;
    hash = (hash * 31) + (unsigned int)rec->sampling_rate;
    hash = (hash * 31) + djb2Hash(rec->read_id);
    hash = (hash * 31) + (unsigned int)rec->read_number;
    hash = (hash * 31) + (unsigned int)rec->mux;
    hash = (hash * 31) + (unsigned int)rec->channel_number;
    hash = (hash * 31) + djb2Hash(rec->run_id);
    hash = (hash * 31) + djb2Hash(rec->flowcell_id);
    hash = (hash * 31) + djb2Hash(rec->position_id);
    hash = (hash * 31) + djb2Hash(rec->experiment_id);
    return hash;
}
void process_pod5_read_set_func_1(rec_t *rec, std::size_t batch_row_count) {
    unsigned int *hash_array = (unsigned int*)malloc(batch_row_count * sizeof(unsigned int));
//    int *thread_num = (int*)malloc(batch_row_count * sizeof(int));
    #pragma omp parallel for
    for(size_t i=0;i<batch_row_count;i++) {
        uint64_t sum = 0;
        for (uint64_t j = 0; j < rec[i].len_raw_signal; j++) {
            sum += ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
        }
        hash_array[i] = compute_hash(sum, &rec[i]);
//        thread_num[i] = omp_get_max_threads();
    }
    for(size_t i=0;i<batch_row_count;i++){
//        fprintf(stdout,"%s\t%u\t%d\n", rec[i].read_id, hash_array[i], thread_num[i]);
        fprintf(stdout,"%s\t%u\n", rec[i].read_id, hash_array[i]);
    }
    free(hash_array);
//    free(thread_num);
    fprintf(stderr,"batch printed with %zu reads\n",batch_row_count);
    for (size_t row = 0; row < batch_row_count; ++row) {
        free(rec[row].read_id);
        free(rec[row].raw_signal);
        free(rec[row].run_id);
        free(rec[row].flowcell_id);
        free(rec[row].position_id);
        free(rec[row].experiment_id);
    }
    free(rec);
}

void process_pod5_read_set_func_0(rec_t *rec, std::size_t batch_row_count) {
    double *sums = (double*)malloc(batch_row_count * sizeof(double));
    #pragma omp parallel for
    for(size_t i=0;i<batch_row_count;i++){
        uint64_t sum = 0;
        for(uint64_t j=0; j<rec[i].len_raw_signal; j++){
            sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
        }
        sums[i] = sum;
    }
    for(size_t i=0;i<batch_row_count;i++){
        fprintf(stdout, "%" PRId64 ",", rec[i].run_acquisition_start_time_ms);
        fprintf(stdout, "%" PRIu16 ",", rec[i].sampling_rate);
        fprintf(stdout, "%s,", rec[i].read_id);
        fprintf(stdout, "%" PRIu64 ",", rec[i].len_raw_signal);
        fprintf(stdout, "%" PRIu64 ",", rec[i].start_sample);
        fprintf(stdout, "%lf,", rec[i].scale);
        fprintf(stdout, "%lf,", rec[i].offset);
        fprintf(stdout, "%" PRIu32 ",", rec[i].read_number);
        fprintf(stdout, "%" PRIu8 ",", rec[i].mux);
        fprintf(stdout, "%" PRIu16 ",", rec[i].channel_number);
        fprintf(stdout, "%s,", rec[i].run_id);
        fprintf(stdout, "%s,", rec[i].flowcell_id);
        fprintf(stdout, "%s,", rec[i].position_id);
        fprintf(stdout, "%s,", rec[i].experiment_id);
        fprintf(stdout,"%f\n", sums[i]);
    }
    free(sums);
    fprintf(stderr,"batch printed with %zu reads\n",batch_row_count);
    for (size_t row = 0; row < batch_row_count; ++row) {
        free(rec[row].read_id);
        free(rec[row].raw_signal);
        free(rec[row].run_id);
        free(rec[row].flowcell_id);
        free(rec[row].position_id);
        free(rec[row].experiment_id);
    }
    free(rec);
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
    rec->run_acquisition_start_time_ms = run_info_data->acquisition_start_time_ms;
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

int load_pod5_reads_from_file_0(const std::string& path, size_t m_num_worker_threads, double* tot_time_ptr) {
    double t0 = 0 ;
    /**** Initialisation and opening of the file ***/
    t0 = realtime();
    pod5_init();
    // Open the file ready for walking:
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
    cxxpool::thread_pool pool{m_num_worker_threads};
    (*tot_time_ptr) += realtime() - t0;

    for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {
        t0 = realtime();
        Pod5ReadRecordBatch_t* batch = nullptr;
        if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
            fprintf(stderr, "Failed to get batch: %s\n", pod5_get_error_string());
            exit(EXIT_FAILURE);
        }
        std::size_t batch_row_count = 0;
        std::vector<std::future<int>> futures;

        if (pod5_get_read_batch_row_count(&batch_row_count, batch) != POD5_OK) {
            fprintf(stderr, "Failed to get batch row count\n");
            exit(EXIT_FAILURE);
        }
        fprintf(stderr, "batch_row_count: %zu\n", batch_row_count);
        rec_t *rec = (rec_t*)malloc(batch_row_count * sizeof(rec_t));
        for (std::size_t row = 0; row < batch_row_count; ++row) {
            futures.push_back(pool.push(load_pod5_read,row, batch, file, &rec[row]));
//            load_pod5_read(row, batch, file, &rec[row]);
        }
        for (auto& v : futures) {
            auto read = v.get();
        }
        if (pod5_free_read_batch(batch) != POD5_OK) {
            fprintf(stderr, "Failed to release batch\n");
            exit(EXIT_FAILURE);
        }
        (*tot_time_ptr) += realtime() - t0;

        //process and print (time not measured as we want to compare to the time it takes to read the file)
//        process_pod5_read_set_func_0(rec, batch_row_count);
        process_pod5_read_set_func_1(rec, batch_row_count);
    }
    t0 = realtime();
    if (pod5_close_and_free_reader(file) != POD5_OK) {
        fprintf(stderr, "Failed to close and free POD5 reader\n");
        exit(EXIT_FAILURE);
    }
    (*tot_time_ptr) += realtime() - t0;
    return 0;
}

int main(int argc, char *argv[]){
    if(argc != 3) {
        fprintf(stderr, "Usage: %s reads.pod5 num_thread\n", argv[0]);
        return EXIT_FAILURE;
    }
    int num_thread = atoi(argv[2]);
    fprintf(stderr,"Using %d threads\n", num_thread);
    omp_set_num_threads(num_thread);

    double tot_time = 0;
    load_pod5_reads_from_file_0(std::string(argv[1]), num_thread, &tot_time);
    fprintf(stderr,"Time for getting samples %f (%d threads)\n", tot_time, num_thread);
    return 0;
}

