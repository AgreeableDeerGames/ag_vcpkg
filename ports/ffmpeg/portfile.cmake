vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ffmpeg/ffmpeg
    REF n4.2
    SHA512 9fa56364696f91e2bf4287954d26f0c35b3f8aad241df3fbd3c9fc617235d8c83b28ddcac88436383b2eb273f690322e6f349e2f9c64d02f0058a4b76fa55035
    HEAD_REF master
    PATCHES
        0001-create-lib-libraries.patch
        0003-fix-windowsinclude.patch
        0004-fix-debug-build.patch
        0005-fix-libvpx-linking.patch
        0006-fix-StaticFeatures.patch
)

if (${SOURCE_PATH} MATCHES " ")
    message(FATAL_ERROR "Error: ffmpeg will not build with spaces in the path. Please use a directory with no spaces")
endif()

vcpkg_find_acquire_program(YASM)
get_filename_component(YASM_EXE_PATH ${YASM} DIRECTORY)

if(VCPKG_TARGET_IS_WINDOWS)
    set(SEP ";")
    #We're assuming that if we're building for Windows we're using MSVC
    set(INCLUDE_VAR "INCLUDE")
    set(LIB_PATH_VAR "LIB")
else()
    set(SEP ":")
    set(INCLUDE_VAR "CPATH")
    set(LIB_PATH_VAR "LIBRARY_PATH")
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    set(ENV{PATH} "$ENV{PATH};${YASM_EXE_PATH}")

    set(BUILD_SCRIPT ${CMAKE_CURRENT_LIST_DIR}\\build.sh)

    if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
        vcpkg_acquire_msys(MSYS_ROOT PACKAGES perl gcc diffutils make)
    else()
        vcpkg_acquire_msys(MSYS_ROOT PACKAGES diffutils make)
    endif()

    set(BASH ${MSYS_ROOT}/usr/bin/bash.exe)
else()
    set(ENV{PATH} "$ENV{PATH}:${YASM_EXE_PATH}")
    set(BASH /bin/bash)
    set(BUILD_SCRIPT ${CMAKE_CURRENT_LIST_DIR}/build_linux.sh)
endif()

set(ENV{${INCLUDE_VAR}} "${CURRENT_INSTALLED_DIR}/include${SEP}$ENV{${INCLUDE_VAR}}")

set(_csc_PROJECT_PATH ffmpeg)

file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)

set(OPTIONS "--enable-asm --enable-yasm --disable-doc --enable-debug")
set(OPTIONS "${OPTIONS} --enable-runtime-cpudetect")

if("nonfree" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-nonfree")
endif()

if("gpl" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-gpl")
endif()

if("version3" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-version3")
endif()

if("openssl" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-openssl")
else()
    set(OPTIONS "${OPTIONS} --disable-openssl")
endif()

if("ffmpeg" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-ffmpeg")
else()
    set(OPTIONS "${OPTIONS} --disable-ffmpeg")
endif()

if("ffplay" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-ffplay")
else()
    set(OPTIONS "${OPTIONS} --disable-ffplay")
endif()

if("ffprobe" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-ffprobe")
else()
    set(OPTIONS "${OPTIONS} --disable-ffprobe")
endif()

if("vpx" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-libvpx")
else()
    set(OPTIONS "${OPTIONS} --disable-libvpx")
endif()

if("x264" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-libx264")
else()
    set(OPTIONS "${OPTIONS} --disable-libx264")
endif()

if("opencl" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-opencl")
else()
    set(OPTIONS "${OPTIONS} --disable-opencl")
endif()

set (ENABLE_LZMA OFF)
if("lzma" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-lzma")
    set (ENABLE_LZMA ON) #necessary for configuring FFMPEG CMake Module
else()
    set(OPTIONS "${OPTIONS} --disable-lzma")
endif()

set (ENABLE_BZIP2 OFF)
if("bzip2" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-bzlib")
    set (ENABLE_BZIP2 ON) #necessary for configuring FFMPEG CMake Module
else()
    set(OPTIONS "${OPTIONS} --disable-bzlib")
endif()

if("avresample" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-avresample")
endif()

if (VCPKG_TARGET_IS_OSX)
    set(OPTIONS "${OPTIONS} --disable-vdpau") # disable vdpau in OSX
endif()

if("nvcodec" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-cuda --enable-nvenc --enable-cuvid --disable-libnpp")
else()
    set(OPTIONS "${OPTIONS} --disable-cuda --disable-nvenc --disable-cuvid --disable-libnpp")
endif()

if("avisynthplus" IN_LIST FEATURES)
    set(OPTIONS "${OPTIONS} --enable-avisynth")
else()
    set(OPTIONS "${OPTIONS} --disable-avisynth")
endif()

set(OPTIONS_CROSS "")

if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(OPTIONS_CROSS " --enable-cross-compile --target-os=win32 --arch=${VCPKG_TARGET_ARCHITECTURE}")
    vcpkg_find_acquire_program(GASPREPROCESSOR)
    foreach(GAS_PATH ${GASPREPROCESSOR})
        get_filename_component(GAS_ITEM_PATH ${GAS_PATH} DIRECTORY)
        set(ENV{PATH} "$ENV{PATH};${GAS_ITEM_PATH}")
    endforeach(GAS_PATH)
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
else()
    message(FATAL_ERROR "Unsupported architecture")
endif()

if(VCPKG_TARGET_IS_UWP)
    set(ENV{LIBPATH} "$ENV{LIBPATH};$ENV{_WKITS10}references\\windows.foundation.foundationcontract\\2.0.0.0\\;$ENV{_WKITS10}references\\windows.foundation.universalapicontract\\3.0.0.0\\")
    set(OPTIONS "${OPTIONS} --disable-programs")
    set(OPTIONS "${OPTIONS} --extra-cflags=-DWINAPI_FAMILY=WINAPI_FAMILY_APP --extra-cflags=-D_WIN32_WINNT=0x0A00")
    set(OPTIONS_CROSS " --enable-cross-compile --target-os=win32 --arch=${VCPKG_TARGET_ARCHITECTURE}")
endif()

set(OPTIONS_DEBUG "--debug") # Note: --disable-optimizations can't be used due to http://ffmpeg.org/pipermail/libav-user/2013-March/003945.html
set(OPTIONS_RELEASE "")

set(OPTIONS "${OPTIONS} ${OPTIONS_CROSS}")

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(OPTIONS "${OPTIONS} --disable-static --enable-shared")
    if (VCPKG_TARGET_IS_UWP)
        set(OPTIONS "${OPTIONS} --extra-ldflags=-APPCONTAINER --extra-ldflags=WindowsApp.lib")
    endif()
endif()

if(VCPKG_TARGET_IS_WINDOWS)
    set(OPTIONS "${OPTIONS} --extra-cflags=-DHAVE_UNISTD_H=0")
    if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
        set(OPTIONS_DEBUG "${OPTIONS_DEBUG} --extra-cflags=-MDd --extra-cxxflags=-MDd")
        set(OPTIONS_RELEASE "${OPTIONS_RELEASE} --extra-cflags=-MD --extra-cxxflags=-MD")
    else()
        set(OPTIONS_DEBUG "${OPTIONS_DEBUG} --extra-cflags=-MTd --extra-cxxflags=-MTd")
        set(OPTIONS_RELEASE "${OPTIONS_RELEASE} --extra-cflags=-MT --extra-cxxflags=-MT")
    endif()
endif()

set(ENV_LIB_PATH "$ENV{${LIB_PATH_VAR}}")
set(ENV{PKG_CONFIG_PATH} "${CURRENT_INSTALLED_DIR}/lib/pkgconfig")

message(STATUS "Building Options: ${OPTIONS}")

# Release build
if (NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL release)
    message(STATUS "Building Release Options: ${OPTIONS_RELEASE}")
    set(ENV{${LIB_PATH_VAR}} "${CURRENT_INSTALLED_DIR}/lib${SEP}${ENV_LIB_PATH}")
    set(ENV{CFLAGS} "${VCPKG_C_FLAGS} ${VCPKG_C_FLAGS_RELEASE}")
    set(ENV{LDFLAGS} "${VCPKG_LINKER_FLAGS}")
    message(STATUS "Building ${_csc_PROJECT_PATH} for Release")
    file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel)
    vcpkg_execute_required_process(
        COMMAND ${BASH} --noprofile --norc "${BUILD_SCRIPT}"
            "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel" # BUILD DIR
            "${SOURCE_PATH}" # SOURCE DIR
            "${CURRENT_PACKAGES_DIR}" # PACKAGE DIR
            "${OPTIONS} ${OPTIONS_RELEASE}"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel
        LOGNAME build-${TARGET_TRIPLET}-rel
    )
endif()

# Debug build
if (NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL debug)
    message(STATUS "Building Debug Options: ${OPTIONS_DEBUG}")
    set(ENV{${LIB_PATH_VAR}} "${CURRENT_INSTALLED_DIR}/debug/lib${SEP}${ENV_LIB_PATH}")
    set(ENV{CFLAGS} "${VCPKG_C_FLAGS} ${VCPKG_C_FLAGS_DEBUG}")
    set(ENV{LDFLAGS} "${VCPKG_LINKER_FLAGS}")
    message(STATUS "Building ${_csc_PROJECT_PATH} for Debug")
    file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg)
    vcpkg_execute_required_process(
        COMMAND ${BASH} --noprofile --norc "${BUILD_SCRIPT}"
            "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg" # BUILD DIR
            "${SOURCE_PATH}" # SOURCE DIR
            "${CURRENT_PACKAGES_DIR}/debug" # PACKAGE DIR
            "${OPTIONS} ${OPTIONS_DEBUG}"
        WORKING_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg
        LOGNAME build-${TARGET_TRIPLET}-dbg
    )
endif()

file(GLOB DEF_FILES ${CURRENT_PACKAGES_DIR}/lib/*.def ${CURRENT_PACKAGES_DIR}/debug/lib/*.def)

if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(LIB_MACHINE_ARG /machine:ARM)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(LIB_MACHINE_ARG /machine:ARM64)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(LIB_MACHINE_ARG /machine:x86)
elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LIB_MACHINE_ARG /machine:x64)
else()
    message(FATAL_ERROR "Unsupported target architecture")
endif()

foreach(DEF_FILE ${DEF_FILES})
    get_filename_component(DEF_FILE_DIR "${DEF_FILE}" DIRECTORY)
    get_filename_component(DEF_FILE_NAME "${DEF_FILE}" NAME)
    string(REGEX REPLACE "-[0-9]*\\.def" "${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX}" OUT_FILE_NAME "${DEF_FILE_NAME}")
    file(TO_NATIVE_PATH "${DEF_FILE}" DEF_FILE_NATIVE)
    file(TO_NATIVE_PATH "${DEF_FILE_DIR}/${OUT_FILE_NAME}" OUT_FILE_NATIVE)
    message(STATUS "Generating ${OUT_FILE_NATIVE}")
    vcpkg_execute_required_process(
        COMMAND lib.exe /def:${DEF_FILE_NATIVE} /out:${OUT_FILE_NATIVE} ${LIB_MACHINE_ARG}
        WORKING_DIRECTORY ${CURRENT_PACKAGES_DIR}
        LOGNAME libconvert-${TARGET_TRIPLET}
    )
endforeach()

# Handle tools
if (VCPKG_TARGET_IS_WINDOWS)
    file(GLOB EXP_FILES ${CURRENT_PACKAGES_DIR}/lib/*.exp ${CURRENT_PACKAGES_DIR}/debug/lib/*.exp)
    file(GLOB LIB_FILES ${CURRENT_PACKAGES_DIR}/bin/*${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX} ${CURRENT_PACKAGES_DIR}/debug/bin/*${VCPKG_TARGET_STATIC_LIBRARY_SUFFIX})
    file(GLOB EXE_FILES_REL ${CURRENT_PACKAGES_DIR}/bin/*${VCPKG_TARGET_EXECUTABLE_SUFFIX})
    file(GLOB EXE_FILES_DBG ${CURRENT_PACKAGES_DIR}/debug/bin/*${VCPKG_TARGET_EXECUTABLE_SUFFIX})
    set(FILES_TO_REMOVE ${EXP_FILES} ${LIB_FILES} ${DEF_FILES} ${EXE_FILES_REL} ${EXE_FILES_DBG})

    if(FILES_TO_REMOVE)
        if (EXE_FILES_REL)
            file(INSTALL ${EXE_FILES_REL} DESTINATION ${CURRENT_PACKAGES_DIR}/tools/${PORT})
            vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/${PORT})
        endif()
        if (EXE_FILES_DBG)
            file(INSTALL ${EXE_FILES_DBG} DESTINATION ${CURRENT_PACKAGES_DIR}/debug/tools/${PORT})
            vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/debug/tools/${PORT})
        endif()
        file(REMOVE ${FILES_TO_REMOVE})
    endif()
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include ${CURRENT_PACKAGES_DIR}/debug/share)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)
endif()

vcpkg_copy_pdbs()

# Handle copyright
file(STRINGS ${CURRENT_BUILDTREES_DIR}/build-${TARGET_TRIPLET}-rel-out.log LICENSE_STRING REGEX "License: .*" LIMIT_COUNT 1)
if(${LICENSE_STRING} STREQUAL "License: LGPL version 2.1 or later")
    set(LICENSE_FILE "COPYING.LGPLv2.1")
elseif(${LICENSE_STRING} STREQUAL "License: LGPL version 3 or later")
    set(LICENSE_FILE "COPYING.LGPLv3")
elseif(${LICENSE_STRING} STREQUAL "License: GPL version 2 or later")
    set(LICENSE_FILE "COPYING.GPLv2")
elseif(${LICENSE_STRING} STREQUAL "License: GPL version 3 or later")
    set(LICENSE_FILE "COPYING.GPLv3")
elseif(${LICENSE_STRING} STREQUAL "License: nonfree and unredistributable")
    set(LICENSE_FILE "COPYING.NONFREE")
    file(WRITE ${SOURCE_PATH}/${LICENSE_FILE} ${LICENSE_STRING})
else()
    message(FATAL_ERROR "Failed to identify license (${LICENSE_STRING})")
endif()

configure_file(${CMAKE_CURRENT_LIST_DIR}/FindFFMPEG.cmake.in ${CURRENT_PACKAGES_DIR}/share/${PORT}/FindFFMPEG.cmake @ONLY)
file(COPY ${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL ${SOURCE_PATH}/${LICENSE_FILE} DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
