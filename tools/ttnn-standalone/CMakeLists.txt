cmake_minimum_required(VERSION 3.16)
project(ttnn-standalone CXX)

set(CMAKE_CXX_STANDARD 20 CACHE STRING "C++ standard to conform to")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# set(CMAKE_VERBOSE_MAKEFILE on)

if(DEFINED ENV{CONFIG})
    message(STATUS "CONFIG is set, CMAKE_BUILD_TYPE being set to $ENV{CONFIG}")
    set(CMAKE_BUILD_TYPE $ENV{CONFIG})
elseif(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Release build is the default" FORCE)
endif()

# Handle env:ARCH_NAME
#
# Due to ttmetal's folder structure, we need to do some overriding for ARCH_NAME (e.g. wormhole_b0 -> wormhole)
#
if ("$ENV{ARCH_NAME}" STREQUAL "grayskull")
  set(ARCH_NAME "grayskull")
  set(ARCH_EXTRA_DIR "grayskull")
elseif ("$ENV{ARCH_NAME}" STREQUAL "wormhole_b0")
  set(ARCH_NAME "wormhole")
  set(ARCH_EXTRA_DIR "wormhole/wormhole_b0_defines")
elseif ("$ENV{ARCH_NAME}" STREQUAL "blackhole")
  set(ARCH_NAME "blackhole")
  set(ARCH_EXTRA_DIR "blackhole")
else()
  message(FATAL_ERROR "Unsupported ARCH_NAME: $ENV{ARCH_NAME}")
endif()

# Find clang 17
#
find_program(CLANG_17 clang++-17)
if(CLANG_17)
    message(STATUS "Found Clang-17 here: ${CLANG_17}")
    set(CMAKE_CXX_COMPILER "${CLANG_17}")
else()
    message(WARNING "Clang++-17 not found!!!")
endif()

if("$ENV{TT_METAL_HOME}" STREQUAL "")
    message(FATAL_ERROR "TT_METAL_HOME is not set")
endif()
if("$ENV{ARCH_NAME}" STREQUAL "")
    message(FATAL_ERROR "ARCH_NAME is not set")
endif()

message($ENV{TT_METAL_HOME}/tt_metal/third_party/src/firmware/riscv/$ENV{ARCH_NAME})

add_executable(ttnn-standalone ttnn-standalone.cpp)
set_property(TARGET ttnn-standalone PROPERTY CXX_STANDARD 20)

target_include_directories(ttnn-standalone PRIVATE
    # reflect
    # TODO: Remove this when ttmetal removes this dependency (reflect) from public facing headers
    $ENV{TT_METAL_HOME}/.cpmcache/reflect/e75434c4c5f669e4a74e4d84e0a30d7249c1e66f

    # Metalium
    $ENV{TT_METAL_HOME}
    $ENV{TT_METAL_HOME}/tt_metal
    $ENV{TT_METAL_HOME}/tt_metal/third_party/umd
    $ENV{TT_METAL_HOME}/tt_metal/third_party/fmt
    $ENV{TT_METAL_HOME}/tt_metal/hw/inc
    $ENV{TT_METAL_HOME}/tt_metal/hw/inc/${ARCH_NAME}
    $ENV{TT_METAL_HOME}/tt_metal/hw/inc/${ARCH_EXTRA_DIR}
    $ENV{TT_METAL_HOME}/tt_metal/third_party/umd/src/firmware/riscv/${ARCH_NAME}
    $ENV{TT_METAL_HOME}/tt_metal/third_party/magic_enum

    # TTNN
    $ENV{TT_METAL_HOME}/ttnn/cpp
    $ENV{TT_METAL_HOME}/ttnn/cpp/ttnn
    $ENV{TT_METAL_HOME}/ttnn/cpp/ttnn/deprecated
)

target_link_directories(ttnn-standalone PRIVATE
    $ENV{TT_METAL_HOME}-build/lib
)

target_link_libraries(ttnn-standalone PRIVATE
    # Metalium
    tt_metal
    device
    yaml-cpp
    pthread
    # The below libs have been added to tt-metal repo at some point, but are
    # not currently needed by the standalone - leaving them commented here for
    # reference
    #
    # nng
    # uv

    # TTNN
    # _ttnn  # Why doesn't this work?
    $ENV{TT_METAL_HOME}-build/lib/_ttnn.so
)

target_compile_definitions(ttnn-standalone PRIVATE
    FMT_HEADER_ONLY
)

target_precompile_headers(ttnn-standalone PRIVATE ttnn-precompiled.hpp)
