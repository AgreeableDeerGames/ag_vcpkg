# Automatically generated by scripts/boost/generate-ports.ps1

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO boostorg/integer
    REF boost-1.75.0
    SHA512 ed1b7749052c57e1535005d75ca2fe3707a0fa7bb7261b6ca0c2db12dfbe024aeda4aba2104209b5706f5b1c87bfb9b69115e1433e3f84456a70180e6fbebce5
    HEAD_REF master
)

include(${CURRENT_INSTALLED_DIR}/share/boost-vcpkg-helpers/boost-modular-headers.cmake)
boost_modular_headers(SOURCE_PATH ${SOURCE_PATH})
