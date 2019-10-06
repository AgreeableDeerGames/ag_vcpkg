set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
include(${CURRENT_INSTALLED_DIR}/share/qt5/qt_port_functions.cmake)


list(APPEND CORE_OPTIONS
    -system-tiff
    -system-webp
    -verbose)
    
find_library(TIFF_RELEASE NAMES tiff PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) # Depends on lzma
find_library(TIFF_DEBUG NAMES tiffd PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

find_library(WEBP_RELEASE NAMES webp PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) 
find_library(WEBP_DEBUG NAMES webpd webp PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
find_library(WEBPDEMUX_RELEASE NAMES webpdemux PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH) 
find_library(WEBPDEMUX_DEBUG NAMES webpdemuxd webpdemux PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)
# Depends on opengl in default build but might depend on giflib, libjpeg-turbo, zlib, libpng, tiff, freeglut (!osx), sdl1 (windows) 
# which would require extra libraries to be linked e.g. giflib freeglut sdl1 other ones are already linked

#Dependent libraries
find_library(LZMA_RELEASE lzma PATHS "${CURRENT_INSTALLED_DIR}/lib" NO_DEFAULT_PATH)
find_library(LZMA_DEBUG lzmad lzma PATHS "${CURRENT_INSTALLED_DIR}/debug/lib" NO_DEFAULT_PATH)

set(OPT_REL "TIFF_LIBS=${TIFF_RELEASE} ${LZMA_RELEASE}"
            "WEBP_LIBS=${WEBP_RELEASE} ${WEBPDEMUX_RELEASE}")
set(OPT_DBG "TIFF_LIBS=${TIFF_DEBUG} ${LZMA_DEBUG}"
            "WEBP_LIBS=${WEBP_DEBUG} ${WEBPDEMUX_DEBUG}")
qt_submodule_installation(BUILD_OPTIONS ${CORE_OPTIONS} BUILD_OPTIONS_RELEASE ${OPT_REL} BUILD_OPTIONS_DEBUG ${OPT_DBG})