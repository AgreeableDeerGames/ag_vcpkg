vcpkg_buildpath_length_warning(37)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO aws/aws-sdk-cpp
    REF 819b17b3915b1e6a9b704998efcaa51711dd1357 # 1.8.4
    SHA512 73647ca3426226236c476533d31038ebc8763d3f604b36089b10e645296c5012041cbc2c5bb8cec5d9ae593fe266edbef7bf278c924746f25186d3e6fc183158
    HEAD_REF master
)

string(COMPARE EQUAL "${VCPKG_CRT_LINKAGE}" "dynamic" FORCE_SHARED_CRT)

set(BUILD_ONLY core)

include(${CMAKE_CURRENT_LIST_DIR}/compute_build_only.cmake)

string(REPLACE ";" "\\\\\\\\\\\;" BUILD_ONLY "${BUILD_ONLY}")

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    DISABLE_PARALLEL_CONFIGURE
    PREFER_NINJA
    OPTIONS
        -DENABLE_UNITY_BUILD=ON
        -DENABLE_TESTING=OFF
        -DFORCE_SHARED_CRT=${FORCE_SHARED_CRT}
        -DCMAKE_DISABLE_FIND_PACKAGE_Git=TRUE
        "-DBUILD_ONLY=${BUILD_ONLY}"
        -DBUILD_DEPS=OFF
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake TARGET_PATH share)

vcpkg_copy_pdbs()

file(GLOB_RECURSE AWS_TARGETS "${CURRENT_PACKAGES_DIR}/share/*/*-targets-*.cmake")
foreach(AWS_TARGET IN LISTS AWS_TARGETS)
    file(READ ${AWS_TARGET} _contents)
    string(REGEX REPLACE
        "bin\\/([A-Za-z0-9_.-]+\\.lib)"
        "lib/\\1"
        _contents "${_contents}")
    file(WRITE ${AWS_TARGET} "${_contents}")
endforeach()

file(GLOB AWS_CONFIGS "${CURRENT_PACKAGES_DIR}/share/*/aws-cpp-sdk-*-config.cmake")
list(FILTER AWS_CONFIGS EXCLUDE REGEX "aws-cpp-sdk-core-config\\.cmake\$")
foreach(AWS_CONFIG IN LISTS AWS_CONFIGS)
    file(READ "${AWS_CONFIG}" _contents)
    file(WRITE "${AWS_CONFIG}" "include(CMakeFindDependencyMacro)\nfind_dependency(aws-cpp-sdk-core)\n${_contents}")
endforeach()

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/include
    ${CURRENT_PACKAGES_DIR}/debug/share
    ${CURRENT_PACKAGES_DIR}/share/AWSSDK
    ${CURRENT_PACKAGES_DIR}/lib/pkgconfig
    ${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig
    ${CURRENT_PACKAGES_DIR}/nuget
    ${CURRENT_PACKAGES_DIR}/debug/nuget
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    file(GLOB LIB_FILES ${CURRENT_PACKAGES_DIR}/bin/*.lib)
    if(LIB_FILES)
        file(COPY ${LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/lib)
        file(REMOVE ${LIB_FILES})
    endif()
    file(GLOB DEBUG_LIB_FILES ${CURRENT_PACKAGES_DIR}/debug/bin/*.lib)
    if(DEBUG_LIB_FILES)
        file(COPY ${DEBUG_LIB_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
        file(REMOVE ${DEBUG_LIB_FILES})
    endif()

    file(APPEND ${CURRENT_PACKAGES_DIR}/include/aws/core/SDKConfig.h "#ifndef USE_IMPORT_EXPORT\n#define USE_IMPORT_EXPORT\n#endif")
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
