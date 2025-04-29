#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include "mkr_format/c_api.h"

typedef struct {
    char* read_id;
    double digitisation;
    double offset;
    double scale;
    uint64_t len_raw_signal;
    int16_t* raw_signal;
} rec_t;

int main(int argc, char *argv[]){

    if(argc != 2) {
        fprintf(stderr, "Usage: %s in_file.pod5\n", argv[0]);
        return EXIT_FAILURE;
    }

    mkr_init();

    // Open the file
    MkrFileReader_t* file = mkr_open_combined_file(argv[1]);

    if (!file) {
       fprintf(stderr,"Error in opening file\n");
       perror("perr: ");
       exit(EXIT_FAILURE);
    }

    size_t batch_count = 0;
    if (mkr_get_read_batch_count(&batch_count, file) != MKR_OK) {
        fprintf(stderr, "Failed to query batch count: %s\n", mkr_get_error_string());
    }
    /**** End of init ***/

    int read_count = 0;

    //iterate through batches in the file
    for (size_t batch_index = 0; batch_index < batch_count; ++batch_index) {

        /**** Fetching a batch (disk loading, decompression, parsing in to memory arrays) ***/

        MkrReadRecordBatch_t* batch = NULL;
        if (mkr_get_read_batch(&batch, file, batch_index) != MKR_OK) {
           fprintf(stderr,"Failed to get batch: %s\n", mkr_get_error_string());
        }

        size_t batch_row_count = 0;
        if (mkr_get_read_batch_row_count(&batch_row_count, batch) != MKR_OK) {
            fprintf(stderr,"Failed to get batch row count\n");
        }

        rec_t *rec = (rec_t*)malloc(batch_row_count * sizeof(rec_t));

        // need to find out of this part can be multi-threaded, and if so the best way
        for (size_t row = 0; row < batch_row_count; ++row) {
            boost::uuids::uuid read_id;
            int16_t pore = 0;
            int16_t calibration_idx = 0;
            uint32_t read_number = 0;
            uint64_t start_sample = 0;
            float median_before = 0.0f;
            int16_t end_reason = 0;
            int16_t run_info = 0;
            int64_t signal_row_count = 0;
            if (mkr_get_read_batch_row_info(batch, row, read_id.begin(), &pore, &calibration_idx,
                                            &read_number, &start_sample, &median_before,
                                            &end_reason, &run_info, &signal_row_count) != MKR_OK) {
                fprintf(stderr,"Failed to get read %ld\n", row );
            }
            read_count += 1;

            const char *read_id_tmp = boost::uuids::to_string(read_id).c_str();

            // Now read out the calibration params:
            CalibrationDictData_t *calib_data = NULL;
            if (mkr_get_calibration(batch, calibration_idx, &calib_data) != MKR_OK) {
                fprintf(stderr, "Failed to get read %ld calibration_idx data: %s\n", row,  mkr_get_error_string());
            }

            // Find the absolute indices of the signal rows in the signal table
            uint64_t *signal_rows_indices= (uint64_t*) malloc(signal_row_count * sizeof(uint64_t));

            if (mkr_get_signal_row_indices(batch, row, signal_row_count,
                                           signal_rows_indices) != MKR_OK) {
                fprintf(stderr,"Failed to get read %ld; signal row indices: %s\n", row, mkr_get_error_string());
            }

            // cannot get to work this in C, So using C++
            // Find the locations of each row in signal batches:
            //SignalRowInfo_t *signal_rows = (SignalRowInfo_t *)malloc(sizeof(SignalRowInfo_t)*signal_row_count);
            std::vector<SignalRowInfo_t *> signal_rows(signal_row_count);

            //if (mkr_get_signal_row_info(file, signal_row_count, signal_rows_indices,
                                        //&signal_rows) != MKR_OK) {
            if (mkr_get_signal_row_info(file, signal_row_count, signal_rows_indices,
                                        signal_rows.data()) != MKR_OK) {
                fprintf(stderr,"Failed to get read %ld signal row locations: %s\n", row, mkr_get_error_string());
            }

            size_t total_sample_count = 0;
            for (size_t i = 0; i < signal_row_count; ++i) {
                total_sample_count += signal_rows[i]->stored_sample_count;
            }

            int16_t *samples = (int16_t*)malloc(sizeof(int16_t)*total_sample_count);
            size_t samples_read_so_far = 0;
            for (size_t i = 0; i < signal_row_count; ++i) {
                if (mkr_get_signal(file, signal_rows[i], signal_rows[i]->stored_sample_count,
                                   samples + samples_read_so_far) != MKR_OK) {
                    fprintf(stderr,"Failed to get read  %ld; signal: %s\n", row, mkr_get_error_string());
                    fprintf(stderr,"Failed to get read  %ld; signal: %s\n", row, mkr_get_error_string());
                }

                samples_read_so_far += signal_rows[i]->stored_sample_count;
            }

            rec[row].len_raw_signal = samples_read_so_far;
            rec[row].raw_signal = samples;
            rec[row].scale = calib_data->scale;
            rec[row].offset = calib_data->offset;
            rec[row].read_id = strdup(read_id_tmp);

            mkr_release_calibration(calib_data);
            mkr_free_signal_row_info(signal_row_count, signal_rows.data());

            free(signal_rows_indices);

        }
        /**** Batch fetched ***/

        //process and print
        double *sums = (double*)malloc(batch_row_count * sizeof(double));
        for(int i=0;i<batch_row_count;i++){
            uint64_t sum = 0;
            for(int j=0; j<rec[i].len_raw_signal; j++){
                sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
            }
            sums[i] = sum;
        }

        for(int i=0;i<batch_row_count;i++){
            fprintf(stdout,"%s\t%f\n",rec[i].read_id,sums[i]);
        }
        free(sums);
        fprintf(stderr,"batch printed with %ld reads\n",batch_row_count);

        /**** Deinit ***/
        if (mkr_free_read_batch(batch) != MKR_OK) {
            fprintf(stderr,"Failed to release batch\n");
        }

        for (size_t row = 0; row < batch_row_count; ++row) {
            free(rec[row].read_id);
            free(rec[row].raw_signal);
        }
        free(rec);
        /**** End of Deinit***/

    }

    fprintf(stderr,"Reads: %d\n",read_count);

    return 0;
}


