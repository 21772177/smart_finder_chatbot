cmake_minimum_required(VERSION 3.22)
project("second_brain_llm")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Path to llama.cpp source (set when integrated)
# set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp)

add_library(second_brain_llm SHARED
    llama_jni.cpp
)

target_include_directories(second_brain_llm PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# When llama.cpp is integrated, add:
# target_include_directories(second_brain_llm PRIVATE ${LLAMA_CPP_DIR})
# target_sources(second_brain_llm PRIVATE
#     ${LLAMA_CPP_DIR}/llama.cpp
#     ${LLAMA_CPP_DIR}/ggml.c
#     ${LLAMA_CPP_DIR}/ggml-alloc.c
#     ${LLAMA_CPP_DIR}/ggml-backend.c
#     ${LLAMA_CPP_DIR}/ggml-quants.c
#     ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu.cpp
# )
# target_link_libraries(second_brain_llm PRIVATE log)
# target_compile_definitions(second_brain_llm PRIVATE GGML_USE_CPU)

target_link_libraries(second_brain_llm PRIVATE log)
