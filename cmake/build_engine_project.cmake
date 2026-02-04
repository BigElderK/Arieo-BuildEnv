cmake_minimum_required(VERSION 3.20)

function(build_engine_project)
    set(oneValueArgs
        PRESET
        BUILD_TYPE
        BUILD_FOLDER
        OUTPUT_FOLDER
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    ##########################################################################################
    # set prebuid patches based on preset
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(CMAKE_HOST_BATCH_SUFFIX .bat)
    else()
        set(CMAKE_HOST_BATCH_SUFFIX .sh)
    endif()

    # set prebuid patches based on preset
    if(ARGUMENT_PRESET STREQUAL "android.armv8")
        set(PREBUILD_BATCH $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/host/android/armv8/conanbuild${CMAKE_HOST_BATCH_SUFFIX})
    endif()

    if(ARGUMENT_PRESET STREQUAL "raspberry.armv8")
        set(PREBUILD_BATCH $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/host/raspberry/armv8/conanbuild${CMAKE_HOST_BATCH_SUFFIX})
    endif()

    if(ARGUMENT_PRESET STREQUAL "ubuntu.x86_64")
        set(PREBUILD_BATCH $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/host/ubuntu/x86_64/conanbuild${CMAKE_HOST_BATCH_SUFFIX})
    endif()

    if(ARGUMENT_PRESET STREQUAL "windows.x86_64")
        set(PREBUILD_BATCH $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/host/windows/x86_64/conanbuild${CMAKE_HOST_BATCH_SUFFIX})
    endif()

    if(ARGUMENT_PRESET STREQUAL "macos.arm64")
        set(PREBUILD_BATCH $ENV{ARIEO_PACKAGE_BUILDENV_INSTALL_FOLDER}/host/macos/arm64/conanbuild${CMAKE_HOST_BATCH_SUFFIX})
    endif()

    ##########################################################################################
    # CMake configure steps

    # Configure engine with CMake (using shell to properly chain conan environment setup)
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        execute_process(
            COMMAND cmd /c "${PREBUILD_BATCH} && cmake -B ${ARGUMENT_BUILD_FOLDER} --preset=${ARGUMENT_PRESET} -DCMAKE_BUILD_TYPE=Release -DARIEO_OUTPUT_DIRECTORY=${ARGUMENT_OUTPUT_FOLDER}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE CMAKE_RESULT
            ECHO_OUTPUT_VARIABLE    # This shows output in real time
            ECHO_ERROR_VARIABLE     # This shows errors in real time
            COMMAND_ECHO STDOUT      # Echo the command being executed
        )
    else()
        execute_process(
            COMMAND sh -c "source ${PREBUILD_BATCH} && cmake -B ${ARGUMENT_BUILD_FOLDER} --preset=${ARGUMENT_PRESET} -DCMAKE_BUILD_TYPE=Release -DARIEO_OUTPUT_DIRECTORY=${ARGUMENT_OUTPUT_FOLDER}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE CMAKE_RESULT
            ECHO_OUTPUT_VARIABLE    # This shows output in real time
            ECHO_ERROR_VARIABLE     # This shows errors in real time
            COMMAND_ECHO STDOUT      # Echo the command being executed
        )
    endif()

    if(NOT CMAKE_RESULT EQUAL 0)
        message(FATAL_ERROR "CMake configure failed")
        exit(1)
    endif()

    ##########################################################################################
    # CMake build steps
    # Build engine (using shell to properly chain conan environment setup)
    if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        execute_process(
            COMMAND cmd /c "${PREBUILD_BATCH} && cmake --build ${ARGUMENT_BUILD_FOLDER} --target ArieoEngine"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE CMAKE_RESULT
            ECHO_OUTPUT_VARIABLE    # This shows output in real time
            ECHO_ERROR_VARIABLE     # This shows errors in real time
            COMMAND_ECHO STDOUT      # Echo the command being executed
        )
    else()
        execute_process(
            COMMAND sh -c "source ${PREBUILD_BATCH} && cmake --build ${ARGUMENT_BUILD_FOLDER} --target ArieoEngine"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE CMAKE_RESULT
            ECHO_OUTPUT_VARIABLE    # This shows output in real time
            ECHO_ERROR_VARIABLE     # This shows errors in real time
            COMMAND_ECHO STDOUT      # Echo the command being executed
        )
    endif()

    if(NOT CMAKE_RESULT EQUAL 0)
        message(FATAL_ERROR "CMake build failed")
        exit(1)
    endif()
endfunction()