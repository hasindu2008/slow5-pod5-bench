//g++-9 -Wall -std=c++11 -O2 -I pod5_format/include/ -o pod5_convert_to_pa_rand pod5_convert_to_pa_rand.c pod5_format/lib64/libpod5_format.a  pod5_format/lib64/libarrow.a  pod5_format/lib64/libboost_filesystem.a -lm -lz -lzstd -fopenmp
//loads a batch of reads where the read IDs are in genomic coordinate order (signal+information needed for pA conversion) from file, process the batch (convert to pA and sum), and write output
//only the time for loading a batch to memory (Disk I/O + decompression + parsing and filling the memory arrays) is measured

// to generate read id list: samtools view reads.sorted.bam | awk '{print $1}' > rid.txt

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <sys/time.h>
#include "pod5_format/c_api.h"
#include <vector>
#include <boost/lexical_cast.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <iostream>
#include "cxxpool.h"

constexpr size_t POD5_READ_ID_SIZE = 16;
using ReadID = std::array<uint8_t, POD5_READ_ID_SIZE>;
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
    if (pod5_free_run_info(run_info_data) != POD5_OK) {
        fprintf(stderr, "Failed to free run info\n");
        return EXIT_FAILURE;
    }
    return 0;
}

int main(int argc, char *argv[]){

    if(argc != 5) {
        fprintf(stderr, "Usage: %s reads.pod5 rid_list.txt num_thread batch_size\n", argv[0]);
        return EXIT_FAILURE;
    }

    std::size_t num_thread = atoi(argv[3]);
    int batch_size = atoi(argv[4]);
    fprintf(stderr,"Using %zu threads with batchsize %d\n", num_thread, batch_size);

    std::string path = std::string(argv[1]);

    double tot_time = 0;
    double t0 = 0 ;

   //read id list
    FILE *fpr = fopen(argv[2],"r");
    if(fpr==NULL){
        fprintf(stderr,"Error in opening file %s for reading\n", argv[2]);
        perror("perr: ");;
        exit(EXIT_FAILURE);
    }

    char tmp[1024];

    /**** Initialisation and opening of the file ***/
    t0 = realtime();
    pod5_init();
    // Open the file ready for walking:
    Pod5FileReader_t* file = pod5_open_file(path.c_str());
    if (!file) {
       fprintf(stderr,"Error in opening input pod5 file %s\n", path.c_str());
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
    // We read the input read id list in batches. A batch of read ids is passed to the pod5 funcs to plan the pod5 traversal.
    // Pod5 uses another batching process to retrieve our batch of reads.
    while(1){
        std::vector<ReadID> read_ids;
        int i_count = 0;
        // our batching
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
            std::memcpy(read_id.data(), arr, POD5_READ_ID_SIZE);
            read_ids.push_back(std::move(read_id));
        }

        if(i_count == 0) break;
        int ret = i_count;
        read_count += ret;
        rec_t *rec = (rec_t*)malloc(ret * sizeof(rec_t));

        t0 = realtime();
        // Plan the most efficient route through the file for the required read ids:
        std::vector<std::uint32_t> traversal_batch_counts(batch_count);
        std::vector<std::uint32_t> traversal_batch_rows(ret);
        std::size_t find_success_count = 0;
        std::vector<uint8_t> read_id_array(POD5_READ_ID_SIZE * read_ids.size());
        for (size_t i = 0; i < read_ids.size(); i++) {
            std::memcpy(read_id_array.data() + POD5_READ_ID_SIZE * i, read_ids[i].data(), POD5_READ_ID_SIZE);
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
        // Create static threadpool so it is reused across calls to this function.
        static cxxpool::thread_pool pool{num_thread};

        uint32_t row_offset = 0;
        // pod5 batching
        for (std::size_t batch_index = 0; batch_index < batch_count; ++batch_index) {
            Pod5ReadRecordBatch_t* batch = nullptr;
            if (pod5_get_read_batch(&batch, file, batch_index) != POD5_OK) {
                fprintf(stderr, "Failed to get batch: %s\n", pod5_get_error_string());
                exit(EXIT_FAILURE);
            }
            std::vector<std::future<int>> futures;
            for (std::size_t row_idx = 0; row_idx < traversal_batch_counts[batch_index]; row_idx++) {
                uint32_t row = traversal_batch_rows[row_idx + row_offset];
//                process_pod5_read(row, batch, file, &rec[row_idx + row_offset]);
                futures.push_back(pool.push(process_pod5_read,row, batch, file, &rec[row_idx + row_offset]));
            }
            for (auto& v : futures) {
                auto read = v.get();
            }
            if (pod5_free_read_batch(batch) != POD5_OK) {
                fprintf(stderr, "Failed to release batch\n");
                exit(EXIT_FAILURE);
            }
            row_offset += traversal_batch_counts[batch_index];
        }
        tot_time += realtime() - t0;
        //process and print (time not measured as we want to compare to the time it takes to read the file)
        double *sums = (double*)malloc(ret * sizeof(double));
        for(int i=0;i<ret;i++){
            double sum = 0;
            for(uint64_t j=0; j<rec[i].len_raw_signal; j++){
                sum +=  ((rec[i].raw_signal[j] + rec[i].offset) * rec[i].scale);
            }
            sums[i] = sum;
        }
        for(int i=0;i<ret;i++){
            fprintf(stdout,"%s\t%.3f\n", rec[i].read_id, sums[i]);
        }
        free(sums);
        fprintf(stderr,"batch printed with %d reads\n", ret);
        for (int row = 0; row < ret; ++row) {
            free(rec[row].read_id);
            free(rec[row].raw_signal);
        }
        free(rec);
    }
    t0 = realtime();
    if (pod5_close_and_free_reader(file) != POD5_OK) {
        fprintf(stderr, "Failed to close and free POD5 reader\n");
        exit(EXIT_FAILURE);
    }
    tot_time += realtime() - t0;
    fclose(fpr);
    fprintf(stderr,"Reads: %d\n",read_count);
    fprintf(stderr,"Time for getting samples %f (%zu threads)\n", tot_time, num_thread);
    return 0;
}


