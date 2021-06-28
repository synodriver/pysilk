include_directories(${PROJECT_SOURCE_DIR}/src)
aux_source_directory(${PROJECT_SOURCE_DIR}/src ALL_SRC)
add_library(silk STATIC ${ALL_SRC})
# add_library(silk_s SHARED ${ALL_SRC})
# set_target_properties(silk_s PROPERTIES OUTPUT_NAME "silk")

add_cython_target(transcoder transcoder.pyx)
add_library(transcoder  MODULE ${transcoder})
python_extension_module(transcoder)


add_cython_target(api lowlevelapi.pyx)
add_library(api  MODULE ${api})
python_extension_module(api)

target_link_libraries(transcoder silk.lib)
target_link_libraries(api silk.lib)
# target_include_directories(transcoder PUBLIC ${PROJECT_SOURCE_DIR}/silk/src)

install(TARGETS transcoder LIBRARY DESTINATION silk)
install(TARGETS api LIBRARY DESTINATION silk)
# install(TARGETS silk LIBRARY DESTINATION ${PROJECT_SOURCE_DIR}/silk)
# install(TARGETS silk_s LIBRARY DESTINATION silk)