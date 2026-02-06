cmake_minimum_required(VERSION 3.20)

function(install_engine_project)
    set(oneValueArgs
        BUILD_TYPE
        BUILD_FOLDER
        INSTALL_PREFIX
    )
    
    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    ##########################################################################################
    # Validate required arguments
    if(NOT DEFINED ARGUMENT_BUILD_FOLDER)
        message(FATAL_ERROR "BUILD_FOLDER argument is required")
    endif()

    if(NOT DEFINED ARGUMENT_INSTALL_PREFIX)
        message(FATAL_ERROR "INSTALL_PREFIX argument is required")
    endif()

    if(NOT DEFINED ARGUMENT_BUILD_TYPE)
        message(FATAL_ERROR "BUILD_TYPE argument is required")
    endif()

    ##########################################################################################
    # CMake install steps
    
    message(STATUS "================================================================")
    message(STATUS "Installing project")
    message(STATUS "  Build Folder: ${ARGUMENT_BUILD_FOLDER}")
    message(STATUS "  Install Prefix: ${ARGUMENT_INSTALL_PREFIX}")
    message(STATUS "  Build Type: ${ARGUMENT_BUILD_TYPE}")
    message(STATUS "================================================================")

    # Clean install destination before installing
    if(EXISTS "${ARGUMENT_INSTALL_PREFIX}")
        message(STATUS "Cleaning install destination: ${ARGUMENT_INSTALL_PREFIX}")
        file(REMOVE_RECURSE "${ARGUMENT_INSTALL_PREFIX}")
    endif()

    # Recreate install directory
    file(MAKE_DIRECTORY "${ARGUMENT_INSTALL_PREFIX}")

    # Execute install
    execute_process(
        COMMAND ${CMAKE_COMMAND} --install ${ARGUMENT_BUILD_FOLDER} --prefix ${ARGUMENT_INSTALL_PREFIX} --config ${ARGUMENT_BUILD_TYPE}
        RESULT_VARIABLE CMAKE_RESULT
        ECHO_OUTPUT_VARIABLE    # This shows output in real time
        ECHO_ERROR_VARIABLE     # This shows errors in real time
        COMMAND_ECHO STDOUT      # Echo the command being executed
    )

    if(NOT CMAKE_RESULT EQUAL 0)
        message(FATAL_ERROR "CMake install failed with code ${CMAKE_RESULT}")
        exit(1)
    endif()

    message(STATUS "================================================================")
    message(STATUS "Installation completed successfully")
    message(STATUS "  Installed to: ${ARGUMENT_INSTALL_PREFIX}")
    message(STATUS "================================================================")
endfunction()
