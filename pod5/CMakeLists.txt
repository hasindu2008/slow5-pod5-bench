cmake_minimum_required(VERSION 3.5)
project(slow5_pod5_bench CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Werror -Wall")
include_directories(pod5_format/include)
include_directories(cxxpool/src)

add_executable(pod5_sequential sequential.cpp)
target_link_libraries(pod5_sequential ${CMAKE_CURRENT_SOURCE_DIR}/pod5_format/lib/libpod5_format.so -lpthread -fopenmp)
