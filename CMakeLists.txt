cmake_minimum_required(VERSION 3.14)
project(Arieo-BuildEnv)

set(conan_host_profile_file "")

# CMAKE_CONFIGURE_PRESET is set by install_config.cmake included before this script
# Check if CMAKE_CONFIGURE_PRESET is defined
if(NOT DEFINED CMAKE_CONFIGURE_PRESET)
    message(FATAL_ERROR "Variable CMAKE_CONFIGURE_PRESET is not defined. install_config.cmake should be included first.")
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "android.armv8")
    set(conan_host_profile_file ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.android.armv8.txt)
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "raspberry.armv8")
    set(conan_host_profile_file ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.raspberry.armv8.txt)
endif()

if (${CMAKE_CONFIGURE_PRESET} STREQUAL "ubuntu.x86_64")
    set(conan_host_profile_file ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.ubuntu.x86_64.txt)
endif()

# Add host profiles only for windows platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if (${CMAKE_CONFIGURE_PRESET} STREQUAL "windows.x86_64")
        set(conan_host_profile_file ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.windows.x86_64.txt)
    endif()
else()
    #message(FATAL_ERROR "Windows platform only support Windows host system.")
endif()

# Add host profiles only for darwin platform
if (CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    if (${CMAKE_CONFIGURE_PRESET} STREQUAL "macos.arm64")
        set(conan_host_profile_file ${CMAKE_CURRENT_LIST_DIR}/conan/profiles/host/conan_host_profile.macos.arm64.txt)
    endif()
else()
    #message(FATAL_ERROR "macOS platform only supports Darwin host system.")
endif()

# Use a stamp file to track conan installation completion (preset-specific)
set(CONAN_STAMP_FILE ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET}/.conan_install_complete)

# Ensure the conan directory exists
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET})

add_custom_command(
    OUTPUT ${CONAN_STAMP_FILE}
    DEPENDS 
        ${conan_host_profile_file}
        ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.txt
    COMMAND ${CMAKE_COMMAND} -E echo "Running conan install for ${CMAKE_CONFIGURE_PRESET}"
    COMMAND conan
        install ${CMAKE_CURRENT_LIST_DIR}/conan/conanfile.txt
        --update
        --generator CMakeToolchain
        --output-folder ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET}
        --build=never
        --profile=${conan_host_profile_file}
    COMMAND ${CMAKE_COMMAND} -E touch ${CONAN_STAMP_FILE}
    COMMENT "Running conan install for preset: ${CMAKE_CONFIGURE_PRESET}"
    COMMAND_ERROR_IS_FATAL ANY
    USES_TERMINAL
    VERBATIM
)

# This target will be built as part of ALL
add_custom_target(arieo_build_env ALL
    DEPENDS ${CONAN_STAMP_FILE}
)

# Generate wrapper files from templates
configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/build_environment.cmake.in
    ${CMAKE_BINARY_DIR}/build_environment.cmake
    @ONLY
)

configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/CMakePresets.json.in
    ${CMAKE_BINARY_DIR}/CMakePresets.json
    @ONLY
)

###########################################################################
# Install conan generated files
install(DIRECTORY ${CMAKE_BINARY_DIR}/conan/host/${CMAKE_CONFIGURE_PRESET}/
    DESTINATION conan/host/${CMAKE_CONFIGURE_PRESET}
)

install(
    FILES ${conan_host_profile_file}
    DESTINATION conan/host/${CMAKE_CONFIGURE_PRESET}
)

install(
    FILES ${CMAKE_BINARY_DIR}/CMakePresets.json
    DESTINATION cmake
)

# Install generated wrapper files
install(
    FILES ${CMAKE_BINARY_DIR}/build_environment.cmake
    DESTINATION cmake
)

install(
    FILES ${CMAKE_BINARY_DIR}/CMakePresets.json
    DESTINATION cmake
)

