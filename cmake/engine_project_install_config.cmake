cmake_minimum_required(VERSION 3.31)

# Include CMake helpers for package config generation
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# ==================== Reusable Install Configuration Function ====================
# This function configures CMake installation for a target project
# Handles: library installation, header installation, target export, and config file generation
function(arieo_engine_project_install_configure target_project)
    set(oneValueArgs
        LIBRARY_TYPE  # STATIC, SHARED, or empty for header-only
    )
    
    set(multiValueArgs
        PUBLIC_INCLUDE_FOLDERS  # List of include directories to install
    )
    
    cmake_parse_arguments(
        ARG
        ""
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN})
    
    # Install the library target (skip for header-only libraries)
    install(TARGETS ${target_project}
        EXPORT ${target_project}Targets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    )

    # Install public headers
    if(DEFINED ARG_PUBLIC_INCLUDE_FOLDERS)
        foreach(INCLUDE_FOLDER ${ARG_PUBLIC_INCLUDE_FOLDERS})
            if(EXISTS ${INCLUDE_FOLDER})
                install(DIRECTORY ${INCLUDE_FOLDER}/
                    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
                    FILES_MATCHING
                    PATTERN "*.h"
                    PATTERN "*.hpp"
                    PATTERN "*.hxx"
                    PATTERN "*.inl"
                )
            endif()
        endforeach()
    endif()

    # Export targets for use by other CMake projects
    install(EXPORT ${target_project}Targets
        FILE ${target_project}Targets.cmake
        NAMESPACE arieo::
        DESTINATION cmake
    )

    # Generate and install package configuration file
    # Use common template and substitute target_project name
    set(CONFIG_TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/engine_project_install_config.cmake.in)
    configure_file(
        ${CONFIG_TEMPLATE_FILE}
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}Config.cmake.in
        @ONLY
    )
    
    configure_package_config_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}Config.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}Config.cmake
        INSTALL_DESTINATION cmake
        PATH_VARS CMAKE_INSTALL_INCLUDEDIR CMAKE_INSTALL_LIBDIR
    )

    # Generate version file
    if(PROJECT_VERSION)
        set(PACKAGE_VERSION ${PROJECT_VERSION})
    else()
        set(PACKAGE_VERSION "1.0.0")
    endif()

    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}ConfigVersion.cmake
        VERSION ${PACKAGE_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # Install config files
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${target_project}ConfigVersion.cmake
        DESTINATION cmake
    )
    
endfunction()
