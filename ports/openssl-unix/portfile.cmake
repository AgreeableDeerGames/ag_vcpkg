include(vcpkg_common_functions)

if(VCPKG_CMAKE_SYSTEM_NAME STREQUAL "WindowsStore" OR NOT VCPKG_CMAKE_SYSTEM_NAME)
    message(FATAL_ERROR "This port is only for openssl on Unix-like systems")
endif()

if(EXISTS "${CURRENT_INSTALLED_DIR}/include/openssl/ssl.h")
  message(WARNING "Can't build openssl if libressl is installed. Please remove libressl, and try install openssl again if you need it. Build will continue but there might be problems since libressl is only a subset of openssl")
  set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
  return()
endif()


vcpkg_find_acquire_program(PERL)

set(OPENSSL_VERSION 1.1.1d)

vcpkg_download_distfile(OPENSSL_SOURCE_ARCHIVE
    URLS "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" "https://www.openssl.org/source/old/1.1.1/openssl-${OPENSSL_VERSION}.tar.gz"
    FILENAME "openssl-${OPENSSL_VERSION}.tar.gz"
    SHA512 2bc9f528c27fe644308eb7603c992bac8740e9f0c3601a130af30c9ffebbf7e0f5c28b76a00bbb478bad40fbe89b4223a58d604001e1713da71ff4b7fe6a08a7
)

vcpkg_extract_source_archive_ex(
    OUT_SOURCE_PATH MASTER_COPY_SOURCE_PATH
    ARCHIVE ${OPENSSL_SOURCE_ARCHIVE}
    REF ${OPENSSL_VERSION}
)

if(CMAKE_HOST_WIN32)
    vcpkg_acquire_msys(MSYS_ROOT PACKAGES make)
    set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)
    set(MAKE ${MSYS_ROOT}/usr/bin/make.exe)
else()
    find_program(MAKE make)
    if(NOT MAKE)
        message(FATAL_ERROR "Could not find make. Please install it through your package manager.")
    endif()
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${CMAKE_CURRENT_LIST_DIR}
    PREFER_NINJA
    OPTIONS
        -DSOURCE_PATH=${MASTER_COPY_SOURCE_PATH}
        -DPERL=${PERL}
        -DMAKE=${MAKE}
    OPTIONS_RELEASE
        -DINSTALL_HEADERS=ON
)

vcpkg_install_cmake()

file(GLOB HEADERS ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel/*/include/openssl/*.h)
set(RESOLVED_HEADERS)
foreach(HEADER ${HEADERS})
    get_filename_component(X "${HEADER}" REALPATH)
    list(APPEND RESOLVED_HEADERS "${X}")
endforeach()

file(INSTALL ${RESOLVED_HEADERS} DESTINATION ${CURRENT_PACKAGES_DIR}/include/openssl)
file(INSTALL ${MASTER_COPY_SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/openssl-unix RENAME copyright)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(COPY ${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/openssl)
endif()

vcpkg_test_cmake(PACKAGE_NAME OpenSSL MODULE)
