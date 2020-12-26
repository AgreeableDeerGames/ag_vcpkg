include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO AgreeableDeerGames/GameBackbone
    REF 0.4.1
    SHA512 9b217e0d693f9cf0539e3a7168f5c44ba275b7ee8783dfb2a042765317d8d1b00f731844aad9009b65b92a8512ee4cbd0d20c49004447b70c3fd5fda4a66d8cc
    HEAD_REF master
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/GameBackbone)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(RENAME "${SOURCE_PATH}/LICENSE.txt" "${CURRENT_PACKAGES_DIR}/share/gamebackbone/copyright")