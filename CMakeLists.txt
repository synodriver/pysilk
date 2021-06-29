cmake_minimum_required(VERSION 3.17)
project(silk C)
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/silk)
set(CYTHON_GEN_DIR ${PROJECT_SOURCE_DIR}/silk)
set(CMAKE_C_STANDARD 99)

find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)
# include_directories(./src)

add_subdirectory(silk)




# message(${PROJECT_SOURCE_DIR}/silk/transcoder.pyx)


# add_executable(encoder test/Encoder.c ${C_SOURCE})
# add_executable(decoder test/Decoder.c ${C_SOURCE})