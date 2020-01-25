vcpkg_buildpath_length_warning(37)

#the port produces some empty dlls when building shared libraries, since some components do not export anything, breaking the internal build itself
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO openMVG/openMVG
    REF v1.4
    SHA512 949cf3680375c87b06db0f4713c846422c98d1979d49e9db65761f63f6f3212f0fcd8425f23c6112f04fbbb90b241638c2fd9329bb6b8b612c1d073aac55759a
    PATCHES
        fixcmake.patch
        fix-config-cmake.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    openmp OpenMVG_USE_OPENMP
    opencv OpenMVG_USE_OPENCV
    opencv OpenMVG_USE_OCVSIFT
)

set(ENABLE_OPENCV OFF)
if("opencv" IN_LIST FEATURES)
  set(ENABLE_OPENCV ON)
endif()

set(ENABLE_OPENMP OFF)
if("openmp" IN_LIST FEATURES)
  set(ENABLE_OPENMP ON)
endif()

# remove some deps to prevent conflict
file(REMOVE_RECURSE ${SOURCE_PATH}/src/third_party/ceres-solver
                    ${SOURCE_PATH}/src/third_party/cxsparse
                    ${SOURCE_PATH}/src/third_party/eigen
                    ${SOURCE_PATH}/src/third_party/flann
                    ${SOURCE_PATH}/src/third_party/jpeg
                    ${SOURCE_PATH}/src/third_party/lemon
                    ${SOURCE_PATH}/src/third_party/png
                    ${SOURCE_PATH}/src/third_party/tiff
                    ${SOURCE_PATH}/src/third_party/zlib)

# remove some cmake modules to force using our configs
file(REMOVE_RECURSE ${SOURCE_PATH}/src/cmakeFindModules/FindEigen.cmake
                    ${SOURCE_PATH}/src/cmakeFindModules/FindLemon.cmake
                    ${SOURCE_PATH}/src/cmakeFindModules/FindFlann.cmake
                    ${SOURCE_PATH}/src/cmakeFindModules/FindCoinUtils.cmake
                    ${SOURCE_PATH}/src/cmakeFindModules/FindClp.cmake
                    ${SOURCE_PATH}/src/cmakeFindModules/FindOsi.cmake)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/src
    PREFER_NINJA
    OPTIONS ${FEATURE_OPTIONS}
        -DOpenMVG_BUILD_SHARED=OFF
        -DOpenMVG_BUILD_TESTS=OFF
        -DOpenMVG_BUILD_DOC=OFF
        -DOpenMVG_BUILD_EXAMPLES=OFF
        -DOpenMVG_BUILD_OPENGL_EXAMPLES=OFF
        -DOpenMVG_BUILD_SOFTWARES=OFF
        -DOpenMVG_BUILD_GUI_SOFTWARES=OFF
        -DOpenMVG_BUILD_COVERAGE=OFF
        -DOpenMVG_USE_INTERNAL_CLP=OFF
        -DOpenMVG_USE_INTERNAL_COINUTILS=OFF
        -DOpenMVG_USE_INTERNAL_OSI=OFF
        -DOpenMVG_USE_INTERNAL_EIGEN=OFF
        -DOpenMVG_USE_INTERNAL_CEREAL=OFF
        -DOpenMVG_USE_INTERNAL_CERES=OFF
        -DOpenMVG_USE_INTERNAL_FLANN=OFF
        -DOpenMVG_USE_INTERNAL_LEMON=OFF
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH share/openMVG/cmake)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/debug/share)

#remove extra deprecated cmake target files left in unappropriate folders
file(GLOB REMOVE_CMAKE ${CURRENT_PACKAGES_DIR}/lib/*.cmake)
file(REMOVE_RECURSE ${REMOVE_CMAKE})
file(GLOB REMOVE_CMAKE ${CURRENT_PACKAGES_DIR}/debug/lib/*.cmake)
file(REMOVE_RECURSE ${REMOVE_CMAKE})

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/include/openMVG/image/image_test
                    ${CURRENT_PACKAGES_DIR}/include/openMVG/exif/image_data)

if(OpenMVG_BUILD_SHARED)
    # release
    file(GLOB DLL_FILES  ${CURRENT_PACKAGES_DIR}/lib/*.dll)
    file(COPY ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)
    file(REMOVE_RECURSE ${DLL_FILES})
    # debug
    file(GLOB DLL_FILES  ${CURRENT_PACKAGES_DIR}/debug/lib/*.dll)
    file(COPY ${DLL_FILES} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/bin)
    file(REMOVE_RECURSE ${DLL_FILES})
endif()
vcpkg_copy_pdbs()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/openmvg RENAME copyright)
