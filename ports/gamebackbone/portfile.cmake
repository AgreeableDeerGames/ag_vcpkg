include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lavinrp/GameBackbone
    REF 0.2.0
    SHA512 6a0eb72fef8911ce4ae56163682150150a669d93cf65f24db2608112efb18fedefe314b415cf7d349cfb00a471788f43f85fde97191d6cb2f4be02f08c04b199
    HEAD_REF master
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/GameBackboneSln
    PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/GameBackbone)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(RENAME "${SOURCE_PATH}/LICENSE.txt" "${CURRENT_PACKAGES_DIR}/share/gamebackbone/copyright")