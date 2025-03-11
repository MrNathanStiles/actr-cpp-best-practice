include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(actr_cpp_best_practice_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(actr_cpp_best_practice_setup_options)
  option(actr_cpp_best_practice_ENABLE_HARDENING "Enable hardening" ON)
  option(actr_cpp_best_practice_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    actr_cpp_best_practice_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    actr_cpp_best_practice_ENABLE_HARDENING
    OFF)

  actr_cpp_best_practice_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR actr_cpp_best_practice_PACKAGING_MAINTAINER_MODE)
    option(actr_cpp_best_practice_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(actr_cpp_best_practice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(actr_cpp_best_practice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(actr_cpp_best_practice_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(actr_cpp_best_practice_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(actr_cpp_best_practice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(actr_cpp_best_practice_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(actr_cpp_best_practice_ENABLE_IPO "Enable IPO/LTO" ON)
    option(actr_cpp_best_practice_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(actr_cpp_best_practice_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(actr_cpp_best_practice_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(actr_cpp_best_practice_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(actr_cpp_best_practice_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(actr_cpp_best_practice_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(actr_cpp_best_practice_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(actr_cpp_best_practice_ENABLE_PCH "Enable precompiled headers" OFF)
    option(actr_cpp_best_practice_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      actr_cpp_best_practice_ENABLE_IPO
      actr_cpp_best_practice_WARNINGS_AS_ERRORS
      actr_cpp_best_practice_ENABLE_USER_LINKER
      actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS
      actr_cpp_best_practice_ENABLE_SANITIZER_LEAK
      actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED
      actr_cpp_best_practice_ENABLE_SANITIZER_THREAD
      actr_cpp_best_practice_ENABLE_SANITIZER_MEMORY
      actr_cpp_best_practice_ENABLE_UNITY_BUILD
      actr_cpp_best_practice_ENABLE_CLANG_TIDY
      actr_cpp_best_practice_ENABLE_CPPCHECK
      actr_cpp_best_practice_ENABLE_COVERAGE
      actr_cpp_best_practice_ENABLE_PCH
      actr_cpp_best_practice_ENABLE_CACHE)
  endif()

  actr_cpp_best_practice_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS OR actr_cpp_best_practice_ENABLE_SANITIZER_THREAD OR actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(actr_cpp_best_practice_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(actr_cpp_best_practice_global_options)
  if(actr_cpp_best_practice_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    actr_cpp_best_practice_enable_ipo()
  endif()

  actr_cpp_best_practice_supports_sanitizers()

  if(actr_cpp_best_practice_ENABLE_HARDENING AND actr_cpp_best_practice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED
       OR actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS
       OR actr_cpp_best_practice_ENABLE_SANITIZER_THREAD
       OR actr_cpp_best_practice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${actr_cpp_best_practice_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED}")
    actr_cpp_best_practice_enable_hardening(actr_cpp_best_practice_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(actr_cpp_best_practice_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(actr_cpp_best_practice_warnings INTERFACE)
  add_library(actr_cpp_best_practice_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  actr_cpp_best_practice_set_project_warnings(
    actr_cpp_best_practice_warnings
    ${actr_cpp_best_practice_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(actr_cpp_best_practice_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    actr_cpp_best_practice_configure_linker(actr_cpp_best_practice_options)
  endif()

  include(cmake/Sanitizers.cmake)
  actr_cpp_best_practice_enable_sanitizers(
    actr_cpp_best_practice_options
    ${actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS}
    ${actr_cpp_best_practice_ENABLE_SANITIZER_LEAK}
    ${actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED}
    ${actr_cpp_best_practice_ENABLE_SANITIZER_THREAD}
    ${actr_cpp_best_practice_ENABLE_SANITIZER_MEMORY})

  set_target_properties(actr_cpp_best_practice_options PROPERTIES UNITY_BUILD ${actr_cpp_best_practice_ENABLE_UNITY_BUILD})

  if(actr_cpp_best_practice_ENABLE_PCH)
    target_precompile_headers(
      actr_cpp_best_practice_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(actr_cpp_best_practice_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    actr_cpp_best_practice_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(actr_cpp_best_practice_ENABLE_CLANG_TIDY)
    actr_cpp_best_practice_enable_clang_tidy(actr_cpp_best_practice_options ${actr_cpp_best_practice_WARNINGS_AS_ERRORS})
  endif()

  if(actr_cpp_best_practice_ENABLE_CPPCHECK)
    actr_cpp_best_practice_enable_cppcheck(${actr_cpp_best_practice_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(actr_cpp_best_practice_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    actr_cpp_best_practice_enable_coverage(actr_cpp_best_practice_options)
  endif()

  if(actr_cpp_best_practice_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(actr_cpp_best_practice_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(actr_cpp_best_practice_ENABLE_HARDENING AND NOT actr_cpp_best_practice_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR actr_cpp_best_practice_ENABLE_SANITIZER_UNDEFINED
       OR actr_cpp_best_practice_ENABLE_SANITIZER_ADDRESS
       OR actr_cpp_best_practice_ENABLE_SANITIZER_THREAD
       OR actr_cpp_best_practice_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    actr_cpp_best_practice_enable_hardening(actr_cpp_best_practice_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
