vcpkg_check_linkage(ONLY_STATIC_LIBRARY ONLY_DYNAMIC_CRT)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Microsoft/DirectXMesh
    REF jul2020
    SHA512 27618f56fbce39d908417a44ea42ef0040254888fbb92108ecb06f6d70e06c1b168c0366c01f65c6b3d2c9915e445d1da85a48e11c23980cb4ab4b41e0b2904a
    HEAD_REF master
)

IF (TRIPLET_SYSTEM_ARCH MATCHES "x86")
    SET(BUILD_ARCH "Win32")
ELSE()
    SET(BUILD_ARCH ${TRIPLET_SYSTEM_ARCH})
ENDIF()

if (VCPKG_PLATFORM_TOOLSET STREQUAL "v140")
    set(VS_VERSION "2015")
elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v141")
    set(VS_VERSION "2017")
elseif (VCPKG_PLATFORM_TOOLSET STREQUAL "v142")
    set(VS_VERSION "2019")
else()
    message(FATAL_ERROR "Unsupported platform toolset.")
endif()

if(VCPKG_TARGET_IS_UWP)
    set(SLN_NAME "Windows10_${VS_VERSION}")
else()
    if(TRIPLET_SYSTEM_ARCH STREQUAL "arm64")
        set(SLN_NAME "Desktop_${VS_VERSION}_Win10")
    else()
        set(SLN_NAME "Desktop_${VS_VERSION}")
        
        # fix solution file to include DirectX 12 in build
        file(READ ${SOURCE_PATH}/DirectXMesh/DirectXMesh_${SLN_NAME}.vcxproj _contents)
        string(REPLACE "_WIN32_WINNT=0x0601" "_WIN32_WINNT=0x0A00" _contents "${_contents}")
        file(WRITE ${SOURCE_PATH}/DirectXMesh/DirectXMesh_${SLN_NAME}.vcxproj "${_contents}")
        
        # fix solution file to include DirectX 12 in build
        file(READ ${SOURCE_PATH}/Meshconvert/Meshconvert_${SLN_NAME}.vcxproj _contents)
        string(REPLACE "_WIN32_WINNT=0x0601" "_WIN32_WINNT=0x0A00" _contents "${_contents}")
        file(WRITE ${SOURCE_PATH}/Meshconvert/Meshconvert_${SLN_NAME}.vcxproj "${_contents}")
    endif()
endif()

vcpkg_build_msbuild(
    PROJECT_PATH ${SOURCE_PATH}/DirectXMesh_${SLN_NAME}.sln
    PLATFORM ${TRIPLET_SYSTEM_ARCH}
)

file(INSTALL
    ${SOURCE_PATH}/DirectXMesh/DirectXMesh.h
    ${SOURCE_PATH}/DirectXMesh/DirectXMesh.inl
    DESTINATION ${CURRENT_PACKAGES_DIR}/include
)

file(INSTALL
    ${SOURCE_PATH}/DirectXMesh/Bin/${SLN_NAME}/${BUILD_ARCH}/Debug/DirectXMesh.lib
    ${SOURCE_PATH}/DirectXMesh/Bin/${SLN_NAME}/${BUILD_ARCH}/Debug/DirectXMesh.pdb
    DESTINATION ${CURRENT_PACKAGES_DIR}/debug/lib)
file(INSTALL
    ${SOURCE_PATH}/DirectXMesh/Bin/${SLN_NAME}/${BUILD_ARCH}/Release/DirectXMesh.lib
    ${SOURCE_PATH}/DirectXMesh/Bin/${SLN_NAME}/${BUILD_ARCH}/Release/DirectXMesh.pdb
    DESTINATION ${CURRENT_PACKAGES_DIR}/lib)

if(NOT VCPKG_TARGET_IS_UWP AND NOT TRIPLET_SYSTEM_ARCH STREQUAL "arm64")
    set(TOOL_PATH ${CURRENT_PACKAGES_DIR}/tools/directxmesh)
    file(MAKE_DIRECTORY ${TOOL_PATH})
    file(INSTALL
        ${SOURCE_PATH}/Meshconvert/Bin/${SLN_NAME}/${BUILD_ARCH}/Release/Meshconvert.exe
        DESTINATION ${TOOL_PATH})
endif()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
