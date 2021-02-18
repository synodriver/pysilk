cmake_minimum_required(VERSION 3.17)
project(silk C)

set(CMAKE_C_STANDARD 99)

include_directories(./src)

set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/lib)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/build)
file(GLOB_RECURSE C_SOURCE ./src/*.c)
add_executable(encoder test/Encoder.c ${C_SOURCE})
add_executable(decoder test/Decoder.c ${C_SOURCE})