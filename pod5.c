//g++-9 -Wall -O2 -I pod5_format/include/ -o pod5_pa pod5.c pod5_format/lib64/libpod5_format.a  -lm -lz -lzstd -fopenmp
//loads a batch of reads (signal+information needed for pA conversion) from file, process the batch (convert to pA and sum), and write output
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <omp.h>
#include <sys/time.h>
#include "pod5_format/c_api.h"
#include <vector>

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

int main(int argc, char *argv[]){

    if(argc != 4) {
        fprintf(stderr, "Usage: %s in_file.pod5 num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    // note that batch size of is not really used in POD5 as the concept of a batch seem to be hard coded to the file
    // need to verify if there is a way
    int batch_size = atoi(argv[3]);

    int num_thread = atoi(argv[2]);
    omp_set_num_threads(num_thread);

    double tot_time = 0;
    double t0 = 0 ;

    /**** Initialisation and opening of the file ***/
    t0 = realtime();

    pod5_init();

    // Open the file
    Pod5FileReader_t* file = pod5_open_combined_file(argv[1]);

    if (!file) {
       fprintf(stderr,"Error in opening file\n");
       perror("perr: ");
       exit(EXIT_FAILURE);
    }

    size_t batch_count = 0;
    if (pod5_get_read_batch_count(&batch_count, file) != POD5_OK) {
        fprintf(stderr, "Failed to query batch count: %s\n", pod5_get_error_string());
    }
    tot_time += realtime() - t0;
    /**** End of init ***/

    int read_count = 0;

    //iterate through batches in the file
    for (size_t batch_index = 0; batch_index < batch_count; ++batch_index) {

        /**** Fetching a batch (disk loading, decompression, parsing in to memory arrays) ***/
        double t0 = realtime();

        Pod5ReadRecordBatch_t* batch = NULL;
        if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
           fprintf(stderr,"Failed to get batch: %s\n", pod5_get_error_string());
        }

        size_t batch_row_count = 0;
        if (pod5_get_read_batch_row_count(&batch_row_count, batch) != POD5_OK) {
            fprintf(stderr,"Failed to get batch row count\n");
        }

        rec_t *rec = (rec_t*)malloc(batch_row_count * sizeof(rec_t));

        // need to find out of this part can be multi-threaded, and if so the best way
        for (size_t row = 0; row < batch_row_count; ++row) {
            uint8_t read_id[16];
            int16_t pore = 0;
            int16_t calibration_idx = 0;
            uint32_t read_number = 0;
            uint64_t start_sample = 0;
            float median_before = 0.0f;
            int16_t end_reason = 0;
            int16_t run_info = 0;
            int64_t signal_row_count = 0;
            if (pod5_get_read_batch_row_info(batch, row, read_id, &pore, &calibration_idx,
                                            &read_number, &start_sample, &median_before,
                                            &end_reason, &run_info, &signal_row_count) != POD5_OK) {
                fprintf(stderr,"Failed to get read %ld\n", row );
            }
            read_count += 1;

            char read_id_tmp[37];
            pod5_error_t err = pod5_format_read_id(read_id, read_id_tmp);

            // Now read out the calibration params:
            CalibrationDictData_t *calib_data = NULL;
            if (pod5_get_calibration(batch, calibration_idx, &calib_data) != POD5_OK) {
                fprintf(stderr, "Failed to get read %ld calibration_idx data: %s\n", row,  pod5_get_error_string());
            }

            // Find the absolute indices of the signal rows in the signal table
            uint64_t *signal_rows_indices= (uint64_t*) malloc(signal_row_count * sizeof(uint64_t));

            if (pod5_get_signal_row_indices(batch, row, signal_row_count,
                                           signal_rows_indices) != POD5_OK) {
                fprintf(stderr,"Failed to get read %ld; signal row indices: %s\n", row, pod5_get_error_string());
            }

            // cannot get to work this in C, So using C++
            // Find the locations of each row in signal batches:
            //SignalRowInfo_t *signal_rows = (SignalRowInfo_t *)malloc(sizeof(SignalRowInfo_t)*signal_row_count);
            std::vector<SignalRowInfo_t *> signal_rows(signal_row_count);

            //if (pod5_get_signal_row_info(file, signal_row_count, signal_rows_indices,
                                        //&signal_rows) != POD5_OK) {
            if (pod5_get_signal_row_info(file, signal_row_count, signal_rows_indices,
                                        signal_rows.data()) != POD5_OK) {
                fprintf(stderr,"Failed to get read %ld signal row locations: %s\n", row, pod5_get_error_string());
            }

            size_t total_sample_count = 0;
            for (size_t i = 0; i < signal_row_count; ++i) {
                total_sample_count += signal_rows[i]->stored_sample_count;
            }

            int16_t *samples = (int16_t*)malloc(sizeof(int16_t)*total_sample_count);
            size_t samples_read_so_far = 0;
            for (size_t i = 0; i < signal_row_count; ++i) {
                if (pod5_get_signal(file, signal_rows[i], signal_rows[i]->stored_sample_count,
                                   samples + samples_read_so_far) != POD5_OK) {
                    fprintf(stderr,"Failed to get read  %ld; signal: %s\n", row, pod5_get_error_string());
                    fprintf(stderr,"Failed to get read  %ld; signal: %s\n", row, pod5_get_error_string());
                }

                samples_read_so_far += signal_rows[i]->stored_sample_count;
            }

            rec[row].len_raw_signal = samples_read_so_far;
            rec[row].raw_signal = samples;
            rec[row].scale = calib_data->scale;
            rec[row].offset = calib_data->offset;
            rec[row].read_id = strdup(read_id_tmp);

            pod5_release_calibration(calib_data);
            pod5_free_signal_row_info(signal_row_count, signal_rows.data());

            free(signal_rows_indices);

        }
        tot_time += realtime() - t0;
        /**** Batch fetched ***/

        //process and print (time not measured as we want to compare to the time it takes to read the file)
        double *sums = (double*)malloc(batch_row_count * sizeof(double));
        #pragma omp parallel for
        for(int i=0;i<batch_row_count;i++){
            uint64_t sum = 0;
            for(int j=0; j<rec[i].len_raw_signal; j++){
                sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
            }
            sums[i] = sum;
        }
        free(sums);
        for(int i=0;i<batch_row_count;i++){
            fprintf(stdout,"%s\t%f\n",rec[i].read_id,sums[i]);
        }
        fprintf(stderr,"batch printed with %ld reads\n",batch_row_count);

        /**** Deinit ***/
        t0 = realtime();
        if (pod5_free_read_batch(batch) != POD5_OK) {
            fprintf(stderr,"Failed to release batch\n");
        }

        for (size_t row = 0; row < batch_row_count; ++row) {
            free(rec[row].read_id);
            free(rec[row].raw_signal);
        }
        free(rec);
        tot_time += realtime() - t0;
        /**** End of Deinit***/

    }

    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for getting samples %f\n", tot_time);

    return 0;
}


