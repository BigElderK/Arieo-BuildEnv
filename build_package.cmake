cmake_minimum_required(VERSION 3.20)

# INSTALL_FOLDER must be set from command line or environment variable
if(NOT DEFINED INSTALL_FOLDER)
    # Try to get from environment variable
    if(DEFINED ENV{INSTALL_FOLDER})
        set(INSTALL_FOLDER "$ENV{INSTALL_FOLDER}")
        message(STATUS "Using INSTALL_FOLDER from environment: ${INSTALL_FOLDER}")
    else()
        message(FATAL_ERROR "INSTALL_FOLDER is not defined. Please specify it with -DINSTALL_FOLDER=<path> or set INSTALL_FOLDER environment variable")
    endif()
else()
    message(STATUS "Using INSTALL_FOLDER from command line: ${INSTALL_FOLDER}")
endif()

message(STATUS "Using INSTALL_FOLDER: ${INSTALL_FOLDER}")

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
    OUTPUT_FOLDER ${INSTALL_FOLDER}/host/android/armv8
)

generate_conan_toolchain_profile(
    CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.raspberry.armv8.txt
    OUTPUT_FOLDER ${INSTALL_FOLDER}/host/raspberry/armv8
)

generate_conan_toolchain_profile(
    CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.ubuntu.x86_64.txt
    OUTPUT_FOLDER ${INSTALL_FOLDER}/host/ubuntu/x86_64
)

# Add host profiles only for windows platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    generate_conan_toolchain_profile(
        CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.windows.x86_64.txt
        OUTPUT_FOLDER ${INSTALL_FOLDER}/host/windows/x86_64
    )
else()
    #message(FATAL_ERROR "Windows platform only support Windows host system.")
endif()

# Add host profiles only for darwin platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    generate_conan_toolchain_profile(
        CONAN_PROFILE_FILE ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.macos.arm64.txt
        OUTPUT_FOLDER ${INSTALL_FOLDER}/host/macos/arm64
    )
else()
    #message(FATAL_ERROR "macOS platform only supports Darwin host system.")
endif()