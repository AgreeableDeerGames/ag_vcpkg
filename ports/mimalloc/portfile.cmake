vcpkg_fail_port_install(ON_ARCH "arm" "arm64" ON_TARGET "uwp")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO microsoft/mimalloc
    REF 82684042be1be44d34caecc915fb51755278d843 # v1.6.1
    SHA512 82477501a5fafa4df22c911039b74943275d0932404526692419b5c49d6ccfdd95c1c5a3689211db5cc2a845af039fda4892262b538ac7cdfb5bb35787dd355c
    HEAD_REF master
    PATCHES
        fix-cmake.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    asm         MI_SEE_ASM
    secure      MI_SECURE
    override    MI_OVERRIDE
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS_DEBUG
        -DMI_CHECK_FULL=ON
    OPTIONS_RELEASE
        -DMI_CHECK_FULL=OFF
    OPTIONS
        -DMI_INTERPOSE=ON
        -DMI_USE_CXX=OFF
        -DMI_BUILD_TESTS=OFF
        ${FEATURE_OPTIONS}
)

vcpkg_install_cmake()

vcpkg_copy_pdbs()

file(GLOB lib_directories RELATIVE ${CURRENT_PACKAGES_DIR}/lib "${CURRENT_PACKAGES_DIR}/lib/${PORT}-*")
list(GET lib_directories 0 lib_install_dir)
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/${lib_install_dir}/cmake)

vcpkg_replace_string(
    ${CURRENT_PACKAGES_DIR}/share/${PORT}/mimalloc.cmake
    "lib/${lib_install_dir}/"
    ""
)

file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
)

file(COPY ${CURRENT_PACKAGES_DIR}/lib/${lib_install_dir}/include DESTINATION ${CURRENT_PACKAGES_DIR})

file(REMOVE_RECURSE
    ${CURRENT_PACKAGES_DIR}/debug/lib/${lib_install_dir}
    ${CURRENT_PACKAGES_DIR}/debug/share
    ${CURRENT_PACKAGES_DIR}/lib/${lib_install_dir}
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    vcpkg_replace_string(
        ${CURRENT_PACKAGES_DIR}/include/mimalloc.h
        "!defined(MI_SHARED_LIB)"
        "0 // !defined(MI_SHARED_LIB)"
    )
endif()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
