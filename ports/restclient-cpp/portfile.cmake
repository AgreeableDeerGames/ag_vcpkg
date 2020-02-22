if (VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO mrtazz/restclient-cpp
    REF 0.5.1
    SHA512 d5e17a984af44f863bc7cdc7307c2b06cae9252f86c6c6c2377cdb317f61b6419d8e9aedc5e5ccdb08fd1ee13848ec3b9ef8067a8d26dcf438a5c8793b5a2ce3
    HEAD_REF master
    PATCHES
        0001_fix_cmake_linking.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DCMAKE_DISABLE_FIND_PACKAGE_GTest=TRUE
        -DCMAKE_DISABLE_FIND_PACKAGE_jsoncpp=TRUE
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/restclient-cpp)

vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
