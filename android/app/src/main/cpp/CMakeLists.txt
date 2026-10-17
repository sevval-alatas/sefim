cmake_minimum_required(VERSION 3.18.1)

project(dwg_converter LANGUAGES C CXX)

# LibreDWG başlık dizinleri ve kütüphane yolları
set(LIBREDWG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libredwg)
set(LIBREDWG_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libredwg.so)

if(EXISTS ${LIBREDWG_DIR}/include/dwg.h AND EXISTS ${LIBREDWG_LIBRARY})
    # Prebuilt libredwg.so kütüphanesini içe aktarma
    add_library(libredwg SHARED IMPORTED)
    set_target_properties(libredwg PROPERTIES
        IMPORTED_LOCATION ${LIBREDWG_LIBRARY}
    )
endif()

add_library(
    dwg_converter
    SHARED
    dwg_converter.c
)

if(TARGET libredwg)
    target_compile_definitions(dwg_converter PRIVATE HAS_LIBREDWG)
    target_include_directories(dwg_converter PRIVATE ${LIBREDWG_DIR}/include)
    target_link_libraries(
        dwg_converter
        libredwg
        log
    )
else()
    target_link_libraries(
        dwg_converter
        log
    )
endif()
