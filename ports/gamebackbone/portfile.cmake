include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lavinrp/GameBackbone
    REF 0.2.2
    SHA512 f39d612e595b4a32157f0f2be56bbc095764436c4281eccd2894fb65c8590a1d6d9e02dbeceeecdd4947c3c4516ee2a95b8ef739f56b3e9102c57ec9aea92287
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