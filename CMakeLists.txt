cmake_minimum_required(VERSION 3.26)
project(slow5_pod5_bench CXX)

set(CMAKE_C_STANDARD 11)

include_directories(pod5-0.2.2-Linux/include)
include_directories(cxxpool/src)

add_executable(pod5_convert_to_pa pod5_convert_to_pa.cpp)
target_link_libraries(pod5_convert_to_pa ${CMAKE_CURRENT_SOURCE_DIR}/pod5-0.2.2-Linux/lib/libpod5_format.so -lpthread)

add_executable(pod5_convert_to_pa_rand pod5_convert_to_pa_rand.cpp)
target_link_libraries(pod5_convert_to_pa_rand ${CMAKE_CURRENT_SOURCE_DIR}/pod5-0.2.2-Linux/lib/libpod5_format.so -lpthread -fopenmp)

add_executable(parse_uuid parse_uuid.cpp)
