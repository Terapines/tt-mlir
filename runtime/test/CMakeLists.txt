if (NOT TTMLIR_ENABLE_RUNTIME OR (NOT TT_RUNTIME_ENABLE_TTNN AND NOT TT_RUNTIME_ENABLE_TTMETAL))
  message(FATAL_ERROR "Runtime tests require -DTTMLIR_ENABLE_RUNTIME=ON and at least one backend runtime to be enabled")
endif()

enable_testing()
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
  DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(googletest)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  target_compile_options(gtest PRIVATE -Wno-covered-switch-default)
endif()

include(GoogleTest)

find_package(Python3 REQUIRED COMPONENTS Interpreter Development)
if (NOT Python3_LIBRARIES)
  message(FATAL_ERROR "python libraries not found")
endif()

find_library(FLATBUFFERS_LIB flatbuffers PATHS ${TTMLIR_TOOLCHAIN_DIR}/lib)
if (NOT FLATBUFFERS_LIB)
  message(FATAL_ERROR "flatbuffers library not found")
endif()

add_library(TTRuntimeTEST INTERFACE)
add_dependencies(TTRuntimeTEST TTRuntimeTTNN TTRuntimeTTMetal TTRuntime TTRuntimeDebug TTRuntimeWorkarounds TTMETAL_LIBRARY)
target_include_directories(TTRuntimeTEST INTERFACE
    ${PROJECT_SOURCE_DIR}/runtime/include
    ${PROJECT_BINARY_DIR}/include/ttmlir/Target/Common
    ${TTMLIR_TOOLCHAIN}/include
)

target_link_libraries(TTRuntimeTEST INTERFACE
    TTMETAL_LIBRARY
    TTBinary
    TTRuntime
    TTRuntimeTTNN
    TTRuntimeTTMetal
    TTRuntimeDebug
    TTRuntimeWorkarounds
    ${Python3_LIBRARIES}
    ${FLATBUFFERS_LIB}
    GTest::gtest_main
)

function(add_runtime_gtest test_name)
  add_executable(${test_name} ${ARGN})
  set_property(TARGET ${test_name} PROPERTY CXX_STANDARD 20)
  add_dependencies(${test_name} TTRuntimeTEST)
  target_link_libraries(${test_name} PRIVATE TTRuntimeTEST)
  gtest_discover_tests(${test_name})
endfunction()

add_subdirectory(common)

if (TT_RUNTIME_ENABLE_TTNN)
  add_subdirectory(ttnn)
endif()

if (TT_RUNTIME_ENABLE_TTMETAL)
  add_subdirectory(ttmetal)
endif()
