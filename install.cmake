cmake_minimum_required(VERSION 3.20)

# OUTPUT_BASE_FOLDER must be set from command line
if(NOT DEFINED OUTPUT_BASE_FOLDER)
    message(FATAL_ERROR "OUTPUT_BASE_FOLDER is not defined. Please specify it with -DOUTPUT_BASE_FOLDER=<path>")
endif()

message(STATUS "Using OUTPUT_BASE_FOLDER: ${OUTPUT_BASE_FOLDER}")

function(generate_conan_toolchain_profile)
    set(oneValueArgs
        CONAN_PROFILE_FILE
        OUTPUT_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    execute_process(
        COMMAND conan
            install ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.txt
            --update
            --generator CMakeToolchain
            --output-folder ${ARGUMENT_OUTPUT_FOLDER}
            --build=never
            --profile=${ARGUMENT_CONAN_PROFILE_FILE}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE CONAN_RESULT
        ECHO_OUTPUT_VARIABLE    # This shows output in real time
        ECHO_ERROR_VARIABLE     # This shows errors in real time
        COMMAND_ECHO STDOUT      # Echo the command being executed
    )
    
    if(NOT CONAN_RESULT EQUAL 0)
        message(FATAL_ERROR "Conan install failed")
        exit(1)
    endif()

    # Make all .sh under OUTPUT_FOLDER executable
    if (NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        file(GLOB_RECURSE SH_FILES "${ARGUMENT_OUTPUT_FOLDER}/*.sh")
        foreach(SH_FILE ${SH_FILES})
            execute_process(
                COMMAND chmod +x "${SH_FILE}"
                RESULT_VARIABLE CHMOD_RESULT
            )
            if(NOT CHMOD_RESULT EQUAL 0)
                message(FATAL_ERROR "Failed to make ${SH_FILE} executable")
                exit(1)
            endif()
            message(LOG "Make ${SH_FILE} executable")
        endforeach()
    endif()
endfunction()

generate_conan_toolchain_profile(
    CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.android.armv8.txt
    OUTPUT_FOLDER ${OUTPUT_BASE_FOLDER}/host/android/armv8
)

generate_conan_toolchain_profile(
    CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.raspberry.armv8.txt
    OUTPUT_FOLDER ${OUTPUT_BASE_FOLDER}/host/raspberry/armv8
)

generate_conan_toolchain_profile(
    CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.ubuntu.x86_64.txt
    OUTPUT_FOLDER ${OUTPUT_BASE_FOLDER}/host/ubuntu/x86_64
)

# Add host profiles only for windows platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    generate_conan_toolchain_profile(
        CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.windows.x86_64.txt
        OUTPUT_FOLDER ${OUTPUT_BASE_FOLDER}/host/windows/x86_64
    )
else()
    #message(FATAL_ERROR "Windows platform only support Windows host system.")
endif()

# Add host profiles only for darwin platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    generate_conan_toolchain_profile(
        CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.macos.arm64.txt
        OUTPUT_FOLDER ${OUTPUT_BASE_FOLDER}/host/macos/arm64
    )
else()
    #message(FATAL_ERROR "macOS platform only supports Darwin host system.")
endif()