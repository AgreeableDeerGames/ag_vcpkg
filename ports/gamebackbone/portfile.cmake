include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lavinrp/GameBackbone
    REF 4db5c754586e4269573e182980077f8f37adffc0
    SHA512 974f037fa95ad0bfbf2de94e163aebc3fbe90ed8c4f1119a0e53cf5dad3685834aa21997c69423360e6f4421c081fed7efffbcb2c73af78920e2969f9e01a983
    HEAD_REF feature/i164-GB_Consumable:
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/GameBackbone)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# TODO: handle copyright