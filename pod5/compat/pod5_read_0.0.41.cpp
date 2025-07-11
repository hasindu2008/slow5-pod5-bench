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
    char* read_id;
    double offset;
    double scale;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
} rec_t;

void process_read_batch(rec_t *rec_list, int n){
    uint64_t *sums = (uint64_t*)malloc(sizeof(uint64_t)*n);

    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        uint64_t sum = 0;
        for(size_t j=0; j<rec->len_raw_signal; j++){
            sum +=  ((rec->raw_signal[j] + rec->offset) * rec->scale);
        }
        sums[i] = sum;
    }

    //fprintf(stderr,"batch processed with %d reads\n",n);

    for(int i=0;i<n;i++){
        rec_t *rec = &rec_list[i];
        fprintf(stdout,"%s\t%ld\n",rec->read_id,sums[i]);
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
    rec->scale = read_data.calibration_scale;
    rec->offset = read_data.calibration_offset;

    if (pod5_release_run_info(run_info_data) != POD5_OK) {
        fprintf(stderr, "Failed to free run info\n");
        return EXIT_FAILURE;
    }
    return 0;
}

int read_and_process_pod5_file(const std::string& path) {

    int read_count = 0;

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