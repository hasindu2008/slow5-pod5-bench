//g++-9 -Wall -std=c++11 -O2 -I pod5_format/include/ -o pod5_convert_to_pa_rand pod5_convert_to_pa_rand.c pod5_format/lib64/libpod5_format.a  pod5_format/lib64/libarrow.a  pod5_format/lib64/libboost_filesystem.a -lm -lz -lzstd -fopenmp
//loads a batch of reads where the read IDs are in genomic coordinate order (signal+information needed for pA conversion) from file, process the batch (convert to pA and sum), and write output
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured

// to generate read id list: samtools view reads.sorted.bam | awk '{print $1}' > rid.txt

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <omp.h>
#include <sys/time.h>
#include "pod5_format/c_api.h"
#include <vector>
#include <boost/lexical_cast.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <iostream>

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

    if(argc != 5) {
        fprintf(stderr, "Usage: %s in_file.pod5 rid_list.txt num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    // note that batch size of is not really used in POD5 as the concept of a batch seem to be hard coded to the file
    // need to verify if there is a way
    int batch_size = atoi(argv[4]);
    int num_thread = atoi(argv[3]);
    omp_set_num_threads(num_thread);

    double tot_time = 0;
    double t0 = 0 ;

   //read id list
    FILE *fpr = fopen(argv[2],"r");
    if(fpr==NULL){
        fprintf(stderr,"Error in opening file %s for reading\n",argv[2]);
        perror("perr: ");;
        exit(EXIT_FAILURE);
    }

    char **rid = (char **)malloc(sizeof(char*)*batch_size);
    char tmp[1024];

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

    std::vector<boost::uuids::uuid> search_uuids;

    while(1){

        int i=0;
        for(i=0; i<batch_size; i++){
            if (fscanf(fpr,"%s",tmp) < 1) {
                break;
            }
            rid[i] = strdup(tmp);
            search_uuids.push_back(boost::lexical_cast<boost::uuids::uuid>(rid[i]));

        }
        int ret = i;
        read_count += ret;

        double t0 = realtime();
        // Plan the most efficient route through the file for the required read ids:
        std::vector<std::uint32_t> traversal_batch_counts(batch_count);
        std::vector<std::uint32_t> traversal_row_indices(ret);
        std::size_t find_success_count = 0;
        if (pod5_plan_traversal(file, (uint8_t*)(uint8_t*)search_uuids.data(), ret,
                                traversal_batch_counts.data(), traversal_row_indices.data(),
                                &find_success_count) != POD5_OK) {
            fprintf(stderr,"Failed to plan traversal of file: %s\n",pod5_get_error_string());
            return EXIT_FAILURE;
        }

        if ((int)find_success_count != ret) {
            fprintf(stderr,"Failed to find %ld reads\n", ret - find_success_count);
            return EXIT_FAILURE;
        }

        std::size_t row_offset = 0;

        tot_time += realtime() - t0;

        // Walk the suggested traversal route, storing read data.
        for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {

            /**** Fetching a batch (disk loading, decompression, parsing in to memory arrays) ***/
            double t0 = realtime();

            Pod5ReadRecordBatch_t* batch = nullptr;
            if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
                std::cerr << "Failed to get batch: " << pod5_get_error_string() << "\n";
                return EXIT_FAILURE;
            }

            rec_t *rec = (rec_t*)malloc(ret * sizeof(rec_t));

            for (std::size_t row_index = 0; row_index < traversal_batch_counts[batch_index];
                ++row_index) {
                std::uint32_t batch_row = traversal_row_indices[row_index + row_offset];
                // Read out the per read details:
                uint8_t read_id[16];
                int16_t pore = 0;
                int16_t calibration = 0;
                uint32_t read_number = 0;
                uint64_t start_sample = 0;
                float median_before = 0.0f;
                int16_t end_reason = 0;
                int16_t run_info = 0;
                int64_t signal_row_count = 0;
                if (pod5_get_read_batch_row_info(batch, batch_row, read_id, &pore, &calibration,
                                                &read_number, &start_sample, &median_before,
                                                &end_reason, &run_info,
                                                &signal_row_count) != POD5_OK) {
                    std::cerr << "Failed to get read " << batch_row << ": " << pod5_get_error_string()
                            << "\n";
                    return EXIT_FAILURE;
                }

                char read_id_tmp[37];
                pod5_error_t err = pod5_format_read_id(read_id, read_id_tmp);

                // Now read out the calibration params:
                CalibrationDictData_t* calib_data = nullptr;
                if (pod5_get_calibration(batch, calibration, &calib_data) != POD5_OK) {
                    std::cerr << "Failed to get read " << batch_row
                            << " calibration data: " << pod5_get_error_string() << "\n";
                    return EXIT_FAILURE;
                }

                // Find the absolute indices of the signal rows in the signal table
                std::vector<std::uint64_t> signal_rows_indices(signal_row_count);
                if (pod5_get_signal_row_indices(batch, batch_row, signal_row_count,
                                                signal_rows_indices.data()) != POD5_OK) {
                    std::cerr << "Failed to get read " << batch_row
                            << " signal row indices: " << pod5_get_error_string() << "\n";
                    return EXIT_FAILURE;
                }

                // Find the locations of each row in signal batches:
                std::vector<SignalRowInfo_t*> signal_rows(signal_row_count);
                if (pod5_get_signal_row_info(file, signal_row_count, signal_rows_indices.data(),
                                            signal_rows.data()) != POD5_OK) {
                    std::cerr << "Failed to get read " << batch_row
                            << " signal row locations: " << pod5_get_error_string() << "\n";
                }

                std::size_t total_sample_count = 0;
                for (int i = 0; i < signal_row_count; ++i) {
                    total_sample_count += signal_rows[i]->stored_sample_count;
                }

                int16_t *samples = (int16_t*)malloc(sizeof(int16_t)*total_sample_count);
                std::size_t samples_read_so_far = 0;
                for (int i = 0; i < signal_row_count; ++i) {
                    if (pod5_get_signal(file, signal_rows[i], signal_rows[i]->stored_sample_count,
                                        samples + samples_read_so_far) != POD5_OK) {
                        std::cerr << "Failed to get read " << batch_row
                                << " signal: " << pod5_get_error_string() << "\n";
                    }

                    samples_read_so_far += signal_rows[i]->stored_sample_count;
                }

                rec[row_index].len_raw_signal = samples_read_so_far;
                rec[row_index].raw_signal = samples;
                rec[row_index].scale = calib_data->scale;
                rec[row_index].offset = calib_data->offset;
                rec[row_index].read_id = strdup(read_id_tmp);

                pod5_release_calibration(calib_data);
                pod5_free_signal_row_info(signal_row_count, signal_rows.data());


            }
            row_offset += traversal_batch_counts[batch_index];
            tot_time += realtime() - t0;
            /**** Batch fetched ***/

            //process and print (time not measured as we want to compare to the time it takes to read the file)
            double *sums = (double*)malloc(ret * sizeof(double));

            //#pragma omp parallel for
            for(int i=0;i<ret;i++){
                uint64_t sum = 0;
                for(uint64_t j=0; j<rec[i].len_raw_signal; j++){
                    sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
                }
                sums[i] = sum;
            }
            free(sums);
            for(int i=0;i<ret;i++){
                fprintf(stdout,"%s\t%f\n",rec[i].read_id,sums[i]);
            }
            fprintf(stderr,"batch printed with %d reads\n",ret);


            /**** Deinit ***/
            t0 = realtime();
            if (pod5_free_read_batch(batch) != POD5_OK) {
                std::cerr << "Failed to release batch\n";
                return EXIT_FAILURE;
            }

            for (int row = 0; row < ret; ++row) {
                free(rec[row].read_id);
                free(rec[row].raw_signal);
            }
            free(rec);
            tot_time += realtime() - t0;


        }


        for(int i=0; i<ret; i++){
            free(rid[i]);
        }

        if(ret<batch_size){ //this indicates nothing left to read
            break;
        }

    }

    free(rid);
    fclose(fpr);
    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for getting samples %f\n", tot_time);

    return 0;
}


