//g++-9  -Wall -O2 -I pod5_format/include/ -o pod5_convert_to_pa pod5_convert_to_pa.c pod5_format/lib64/libpod5_format.a  pod5_format/lib64/libarrow.a pod5_format/lib64/libboost_filesystem.a -lm -lz -lzstd -fopenmp
//loads a batch of reads (signal+information needed for pA conversion) from file, process the batch (convert to pA and sum), and write output
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <sys/time.h>
#include <vector>
#include <iostream>
#include "pod5_format/c_api.h"
#include "cxxpool.h"

// 37 = number of bytes in UUID (32 hex digits + 4 dashes + null terminator)
const uint32_t POD5_READ_ID_LEN = 37;

static inline double realtime(void) {
    struct timeval tp;
    struct timezone tzp;
    gettimeofday(&tp, &tzp);
    return tp.tv_sec + tp.tv_usec * 1e-6;
}

typedef struct {
    char* read_id;
    double digitisation;
    double offset;
    double scale;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
} rec_t;

int process_pod5_read(size_t row, Pod5ReadRecordBatch* batch, Pod5FileReader* file, rec_t *rec) {
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
    auto run_acquisition_start_time_ms = run_info_data->acquisition_start_time_ms;
    auto run_sample_rate = run_info_data->sample_rate;

    char read_id_tmp[POD5_READ_ID_LEN];
    pod5_error_t err = pod5_format_read_id(read_data.read_id, read_id_tmp);
    std::string read_id_str(read_id_tmp);

    int16_t *samples = (int16_t*)malloc(sizeof(int16_t)*read_data.num_samples);

    if (pod5_get_read_complete_signal(file, batch, row, read_data.num_samples, samples) != POD5_OK) {
        fprintf(stderr, "Failed to get read %zu signal: %s\"\n", row, pod5_get_error_string());
        return EXIT_FAILURE;
    }

    rec->len_raw_signal = read_data.num_samples;
    rec->raw_signal = samples;
    rec->scale = read_data.calibration_scale;
    rec->offset = read_data.calibration_offset;
    rec->read_id = strdup(read_id_tmp);

    /*
    auto new_read = std::make_shared<dorado::Read>();
    new_read->raw_data = samples;
    new_read->sample_rate = run_sample_rate;

    auto start_time_ms = run_acquisition_start_time_ms +
                         ((read_data.start_sample * 1000) /
                          (uint64_t)run_sample_rate);  // TODO check if this cast is needed
    auto start_time = utils::get_string_timestamp_from_unix_time(start_time_ms);
    new_read->run_acquisition_start_time_ms = run_acquisition_start_time_ms;
    new_read->start_time_ms = start_time_ms;
    new_read->scaling = read_data.calibration_scale;
    new_read->offset = read_data.calibration_offset;
    new_read->read_id = std::move(read_id_str);
    new_read->num_trimmed_samples = 0;
    new_read->attributes.read_number = read_data.read_number;
    new_read->attributes.mux = read_data.well;
    new_read->attributes.num_samples = read_data.num_samples;
    new_read->attributes.channel_number = read_data.channel;
    new_read->attributes.start_time = start_time;
    new_read->run_id = run_info_data->acquisition_id;
    new_read->start_sample = read_data.start_sample;
    new_read->end_sample = read_data.start_sample + read_data.num_samples;
    new_read->flowcell_id = run_info_data->flow_cell_id;
    new_read->is_duplex = false;
    */
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


    (*tot_time_ptr) += realtime() - t0;
    cxxpool::thread_pool pool{m_num_worker_threads};

    for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {
        t0 = realtime();
        Pod5ReadRecordBatch_t* batch = nullptr;
        if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
            fprintf(stderr, "Failed to get batch: %s\n", pod5_get_error_string());
            exit(EXIT_FAILURE);
        }

        std::size_t batch_row_count = 0;
        if (pod5_get_read_batch_row_count(&batch_row_count, batch) != POD5_OK) {
            fprintf(stderr, "Failed to get batch row count\n");
            exit(EXIT_FAILURE);
        }
        fprintf(stderr, "batch_row_count: %zu\n", batch_row_count);
        rec_t *rec = (rec_t*)malloc(batch_row_count * sizeof(rec_t));

        for (std::size_t row = 0; row < batch_row_count; ++row) {
            process_pod5_read(row, batch, file, &rec[row]);
        }

        if (pod5_free_read_batch(batch) != POD5_OK) {
            fprintf(stderr, "Failed to release batch\n");
            exit(EXIT_FAILURE);
        }
        (*tot_time_ptr) += realtime() - t0;

        //process and print (time not measured as we want to compare to the time it takes to read the file)
        double *sums = (double*)malloc(batch_row_count * sizeof(double));

        #pragma omp parallel for
        for(int i=0;i<batch_row_count;i++){
            uint64_t sum = 0;
            for(uint64_t j=0; j<rec[i].len_raw_signal; j++){
                sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
            }
            sums[i] = sum;
        }

        for(int i=0;i<batch_row_count;i++){
            fprintf(stdout,"%s\t%f\n",rec[i].read_id,sums[i]);
        }
        free(sums);
        fprintf(stderr,"batch printed with %zu reads\n",batch_row_count);

        for (int row = 0; row < batch_row_count; ++row) {
            free(rec[row].read_id);
            free(rec[row].raw_signal);
        }
        free(rec);

    }

    if (pod5_close_and_free_reader(file) != POD5_OK) {
        fprintf(stderr, "Failed to close and free POD5 reader\n");
        exit(EXIT_FAILURE);
    }
    return 0;
}



int main(int argc, char *argv[]){

    if(argc != 3) {
        fprintf(stderr, "Usage: %s in_file.pod5 thread_count\n", argv[0]);
        return EXIT_FAILURE;
    }
    int num_thread = atoi(argv[2]);

    double tot_time = 0;

    load_pod5_reads_from_file_0(std::string(argv[1]), num_thread, &tot_time);
    fprintf(stderr,"Time for getting samples %f (%d threads)\n", tot_time, num_thread);

    return 0;
}


