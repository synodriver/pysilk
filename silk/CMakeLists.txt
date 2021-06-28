include_directories(${PROJECT_SOURCE_DIR}/src)
aux_source_directory(${PROJECT_SOURCE_DIR}/src ALL_SRC)
add_library(silk STATIC ${ALL_SRC})


add_cython_target(transcoder transcoder.pyx ${ALL_SRC})
add_library(transcoder  MODULE ${transcoder})
python_extension_module(transcoder)
target_link_libraries(transcoder silk)
# target_include_directories(transcoder PUBLIC ${PROJECT_SOURCE_DIR}/silk/src)

install(TARGETS transcoder LIBRARY DESTINATION silk)