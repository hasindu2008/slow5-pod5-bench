cmake_minimum_required(VERSION 3.5)
project(slow5_pod5_bench CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Werror -Wall")
include_directories(pod5_format/include)
include_directories(cxxpool/src)

add_executable(pod5_convert_to_pa pod5_convert_to_pa.cpp)
target_link_libraries(pod5_convert_to_pa ${CMAKE_CURRENT_SOURCE_DIR}/pod5_format/lib/libpod5_format.so -lpthread -fopenmp)
#target_link_libraries(pod5_convert_to_pa ${CMAKE_CURRENT_SOURCE_DIR}/pod5_format/lib64/libpod5_format.a -lpthread)

#add_executable(pod5_convert_to_pa_rand pod5_convert_to_pa_rand.cpp)
#target_link_libraries(pod5_convert_to_pa_rand ${CMAKE_CURRENT_SOURCE_DIR}/pod5_format/lib/libpod5_format.so -lpthread -fopenmp)

#add_executable(pod5_convert_to_pa_rand_2 pod5_convert_to_pa_rand_2.cpp)
#target_link_libraries(pod5_convert_to_pa_rand_2 ${CMAKE_CURRENT_SOURCE_DIR}/pod5-0.2.2-Linux/lib/libpod5_format.so -lpthread -fopenmp)

add_executable(parse_uuid parse_uuid.cpp)