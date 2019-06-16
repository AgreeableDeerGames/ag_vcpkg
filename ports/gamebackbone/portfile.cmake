include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lavinrp/GameBackbone
    REF 0.2.1
    SHA512 94bbf739255bb5a959cde207ab7f989dc473a5bcf12e669d5e97d0e7ee5ec681919a531ba00e4efe3d02b6e0dce427e0596f47534f49edbb69a0b8e641e6d197
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