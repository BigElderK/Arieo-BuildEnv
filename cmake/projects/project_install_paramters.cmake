include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
function(project_install_paramters target_project)
    set(oneValueArgs 
        RUNTIME_INSTALL_DIR
        ARCHIVE_INSTALL_DIR
        LIBRARY_INSTALL_DIR
        INCLUDE_INSTALL_DIR
    )

    cmake_parse_arguments(
        ARGUMENT
        ""
        "${oneValueArgs}"
        ""
        ${ARGN}
    )

    #set default output directories if not provided
    if(NOT DEFINED ARGUMENT_RUNTIME_INSTALL_DIR)
        set(ARGUMENT_RUNTIME_INSTALL_DIR "$ENV{ARIEO_PACKAGES_BUILD_INSTALL_DIR}/${ARIEO_PACKAGE_CATEGORY}/${ARIEO_PACKAGE_NAME}/${ARIEO_BUILD_CONFIGURE_PRESET}/bin/${CMAKE_BUILD_TYPE}")
    endif()
    if(NOT DEFINED ARGUMENT_ARCHIVE_INSTALL_DIR)
        set(ARGUMENT_ARCHIVE_INSTALL_DIR "$ENV{ARIEO_PACKAGES_BUILD_INSTALL_DIR}/${ARIEO_PACKAGE_CATEGORY}/${ARIEO_PACKAGE_NAME}/${ARIEO_BUILD_CONFIGURE_PRESET}/lib/${CMAKE_BUILD_TYPE}")
    endif()
    if(NOT DEFINED ARGUMENT_LIBRARY_INSTALL_DIR)
        set(ARGUMENT_LIBRARY_INSTALL_DIR "$ENV{ARIEO_PACKAGES_BUILD_INSTALL_DIR}/${ARIEO_PACKAGE_CATEGORY}/${ARIEO_PACKAGE_NAME}/${ARIEO_BUILD_CONFIGURE_PRESET}/lib/${CMAKE_BUILD_TYPE}")
    endif()
    if(NOT DEFINED ARGUMENT_INCLUDE_INSTALL_DIR)
        set(ARGUMENT_INCLUDE_INSTALL_DIR "$ENV{ARIEO_PACKAGES_BUILD_INSTALL_DIR}/${ARIEO_PACKAGE_CATEGORY}/${ARIEO_PACKAGE_NAME}/${ARIEO_BUILD_CONFIGURE_PRESET}/include") # Default to static library if not specified
    endif()

    # Determine package name for config files from ARIEO_PACKAGE_NAME variable
    if(NOT DEFINED ARIEO_PACKAGE_NAME)
        message(FATAL_ERROR "ARIEO_PACKAGE_NAME variable is not defined")
    endif()
    
    # Track all targets for this package using a cache variable
    # This allows multiple targets to be accumulated under the same package
    if(NOT DEFINED ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME})
        set(ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME} "" CACHE INTERNAL "List of targets for package ${ARIEO_PACKAGE_NAME}")
    endif()
    list(APPEND ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME} ${target_project})
    set(ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME} "${ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME}}" CACHE INTERNAL "List of targets for package ${ARIEO_PACKAGE_NAME}")
    
    message(STATUS "Registered target ${target_project} for package ${ARIEO_PACKAGE_NAME}")
    message(STATUS "Current targets for ${ARIEO_PACKAGE_NAME}: ${ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME}}")
    
    # Get include directories from target properties
    get_target_property(PUBLIC_INCLUDE_DIRS ${target_project} INTERFACE_INCLUDE_DIRECTORIES)
    
    # Install the library target
    # Note: INCLUDES DESTINATION only sets metadata (tells consumers where to look for headers)
    #       It does NOT copy any files - we need separate install(DIRECTORY) commands below
    # Libraries are installed to build-type subdirectories to support multi-config installs
    # IMPORTANT: Use ARIEO_PACKAGE_NAME for EXPORT to group all targets under same export
    # Note: Both LIBRARY (.so/.dylib) and RUNTIME (.dll) go to bin folder for unified runtime loading
    install(TARGETS ${target_project}
        EXPORT ${ARIEO_PACKAGE_NAME}Targets
        ARCHIVE DESTINATION ${ARGUMENT_ARCHIVE_INSTALL_DIR}
        LIBRARY DESTINATION ${ARGUMENT_LIBRARY_INSTALL_DIR}
        RUNTIME DESTINATION ${ARGUMENT_RUNTIME_INSTALL_DIR}
        INCLUDES DESTINATION ${ARGUMENT_INCLUDE_INSTALL_DIR}
    )

    # Install public headers - actually copies the header files to the install destination
    # Extract paths from generator expressions
    set(EXTRACTED_INCLUDE_DIRS "")
    if(PUBLIC_INCLUDE_DIRS AND NOT PUBLIC_INCLUDE_DIRS STREQUAL "PUBLIC_INCLUDE_DIRS-NOTFOUND")
        foreach(INCLUDE_DIR ${PUBLIC_INCLUDE_DIRS})
            # Extract path from $<BUILD_INTERFACE:path> generator expression
            if(INCLUDE_DIR MATCHES "\\$<BUILD_INTERFACE:(.+)>")
                list(APPEND EXTRACTED_INCLUDE_DIRS "${CMAKE_MATCH_1}")
            elseif(NOT INCLUDE_DIR MATCHES "\\$<INSTALL_INTERFACE:")
                # If it's not a generator expression, use it directly
                list(APPEND EXTRACTED_INCLUDE_DIRS "${INCLUDE_DIR}")
            endif()
        endforeach()
    endif()
    
    set(PUBLIC_INCLUDE_DIRS "${EXTRACTED_INCLUDE_DIRS}")
    if(PUBLIC_INCLUDE_DIRS)
        foreach(INCLUDE_FOLDER ${PUBLIC_INCLUDE_DIRS})
            if(EXISTS ${INCLUDE_FOLDER})
                install(DIRECTORY ${INCLUDE_FOLDER}/
                    DESTINATION ${ARGUMENT_INCLUDE_INSTALL_DIR}
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
    # Use ARIEO_PACKAGE_NAME for the export file to match find_package() expectations
    # This export includes all targets registered under this package name
    install(EXPORT ${ARIEO_PACKAGE_NAME}Targets
        FILE ${ARIEO_PACKAGE_NAME}Targets.cmake
        NAMESPACE ${ARIEO_PACKAGE_NAME}::
        DESTINATION cmake
    )
    

    # Generate and install package configuration file
    # Use common template and substitute ARIEO_PACKAGE_NAME and target_project
    # Note: configure_package_config_file() handles both @variable@ substitution 
    # AND @PACKAGE_...@ path transformations, so we don't need configure_file() first
    set(CONFIG_TEMPLATE_FILE ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/templates/project_install_config.cmake.in)
    
    # Build list of all exported targets with package namespace
    set(package_exported_targets "")
    foreach(target ${ARIEO_PACKAGE_TARGETS_${ARIEO_PACKAGE_NAME}})
        if(package_exported_targets)
            string(APPEND package_exported_targets " ")
        endif()
        string(APPEND package_exported_targets "${ARIEO_PACKAGE_NAME}::${target}")
    endforeach()
    
    # Set variables for template substitution
    set(target_project_name ${target_project})
    set(package_targets_list ${package_exported_targets})
    
    # Generate find_dependency calls for required packages
    # This ensures transitive dependencies are properly resolved for consumers
    set(package_dependencies_code "")
    if(DEP_THIRDPARTY_PACKAGES)
        foreach(pkg ${DEP_THIRDPARTY_PACKAGES})
            string(APPEND package_dependencies_code "find_dependency(${pkg} REQUIRED)\n")
        endforeach()
    endif()
    # Also add ARIEO_PACKAGES dependencies
    if(DEP_ARIEO_PACKAGES)
        foreach(pkg ${DEP_ARIEO_PACKAGES})
            string(APPEND package_dependencies_code "find_dependency(${pkg} REQUIRED)\n")
        endforeach()
    endif()
    
    configure_package_config_file(
        ${CONFIG_TEMPLATE_FILE}
        ${CMAKE_CURRENT_BINARY_DIR}/${ARIEO_PACKAGE_NAME}Config.cmake
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
        ${CMAKE_CURRENT_BINARY_DIR}/${ARIEO_PACKAGE_NAME}ConfigVersion.cmake
        VERSION ${PACKAGE_VERSION}
        COMPATIBILITY SameMajorVersion
    )

    # Install config files
    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/${ARIEO_PACKAGE_NAME}Config.cmake
        ${CMAKE_CURRENT_BINARY_DIR}/${ARIEO_PACKAGE_NAME}ConfigVersion.cmake
        DESTINATION cmake
    )
endfunction()