cmake_minimum_required(VERSION 3.18.1)

project(dwg_converter LANGUAGES C CXX)

# LibreDWG başlık dizinleri ve kütüphane yolları
set(LIBREDWG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libredwg)

if(EXISTS ${LIBREDWG_DIR}/include/dwg.h)
    add_definitions(-DHAS_LIBREDWG)
    include_directories(${LIBREDWG_DIR}/include)

    # Prebuilt libredwg.so kütüphanesini içe aktarma
    add_library(libredwg SHARED IMPORTED)
    set_target_properties(libredwg PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libredwg.so
    )
endif()

add_library(
    dwg_converter
    SHARED
    dwg_converter.c
)

if(EXISTS ${LIBREDWG_DIR}/include/dwg.h)
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
