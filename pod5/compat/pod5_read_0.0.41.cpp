//The code for multi-threaded sequential access of POD5 files is based on the code used in Dorado v0.7.0 (https://github.com/nanoporetech/dorado/blob/9ac85c65fc873a956bda00b2f5608b2bf72d9e7c/dorado/data_loader/DataLoader.cpp#L876)

#include <stdio.h>
#include <stdlib.h>
#include "pod5_format/c_api.h"
#include <inttypes.h>
#include <string.h>
#include <string>
#include <vector>
// 37 = number of bytes in UUID (32 hex digits + 4 dashes + null terminator)
const uint32_t POD5_READ_ID_LEN = 37;

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
        fprintf(stdout, "%" PRId64 "\t", rec->run_acquisition_start_time);

        fprintf(stdout, "\n");
    }
    //fprintf(stderr,"batch printed with %d reads\n",n);

    free(sums);
    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        free(rec->raw_signal);
        free(rec->read_id);
        free((char*)rec->run_id);
        free((char*)rec->flowcell_id);
        free((char*)rec->position_id);
        free((char*)rec->experiment_id);
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

    if (pod5_release_run_info(run_info_data) != POD5_OK) {
        fprintf(stderr, "Failed to free run info\n");
        return EXIT_FAILURE;
    }
    return 0;
}

int read_and_process_pod5_file(const std::string& path) {

    int read_count = 0;
    print_header();

    /**** Initialisation and opening of the file ***/

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
    /**** End of init ***/

    for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {

        /**** Fetching a batch ***/

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

        read_count += batch_row_count;

        rec_t *rec = (rec_t*)malloc(batch_row_count * sizeof(rec_t));
        for (std::size_t row = 0; row < batch_row_count; ++row) {
            load_pod5_read(row, batch, file, &rec[row]);
        }

        /**** Batch fetched ***/

        //fprintf(stderr,"batch loaded with %zu reads\n", batch_row_count);

        //process and print (time not measured as we want to compare to the time it takes to read the file)
        process_read_batch(rec, batch_row_count);

        /**** Deinit ***/
        if (pod5_free_read_batch(batch) != POD5_OK) {
            fprintf(stderr, "Failed to release batch\n");
            exit(EXIT_FAILURE);
        }
        /**** End of Deinit***/

    }

    /**** Deinit ***/

    if (pod5_close_and_free_reader(file) != POD5_OK) {
        fprintf(stderr, "Failed to close and free POD5 reader\n");
        exit(EXIT_FAILURE);
    }

    /**** End of Deinit***/
    return read_count;
}



int main(int argc, char *argv[]) {

    if(argc != 2) {
        fprintf(stderr, "Usage: %s reads.pod5\n", argv[0]);
        return EXIT_FAILURE;
    }

    const char *path = argv[1];

    int read_count = 0;
    read_count = read_and_process_pod5_file(path);
    fprintf(stderr,"Reads: %d\n",read_count);
    return 0;
}