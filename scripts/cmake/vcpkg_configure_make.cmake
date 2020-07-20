## # vcpkg_configure_make
##
## Configure configure for Debug and Release builds of a project.
##
## ## Usage
## ```cmake
## vcpkg_configure_make(
##     SOURCE_PATH <${SOURCE_PATH}>
##     [AUTOCONFIG]
##     [NO_DEBUG]
##     [SKIP_CONFIGURE]
##     [PROJECT_SUBPATH <${PROJ_SUBPATH}>]
##     [PRERUN_SHELL <${SHELL_PATH}>]
##     [OPTIONS <-DUSE_THIS_IN_ALL_BUILDS=1>...]
##     [OPTIONS_RELEASE <-DOPTIMIZE=1>...]
##     [OPTIONS_DEBUG <-DDEBUGGABLE=1>...]
## )
## ```
##
## ## Parameters
## ### SOURCE_PATH
## Specifies the directory containing the `configure`/`configure.ac`.
## By convention, this is usually set in the portfile as the variable `SOURCE_PATH`.
##
## ### PROJECT_SUBPATH
## Specifies the directory containing the ``configure`/`configure.ac`.
## By convention, this is usually set in the portfile as the variable `SOURCE_PATH`.
##
## ### SKIP_CONFIGURE
## Skip configure process
##
## ### AUTOCONFIG
## Need to use autoconfig to generate configure file.
##
## ### PRERUN_SHELL
## Script that needs to be called before configuration (do not use for batch files which simply call autoconf or configure)
##
## ### OPTIONS
## Additional options passed to configure during the configuration.
##
## ### OPTIONS_RELEASE
## Additional options passed to configure during the Release configuration. These are in addition to `OPTIONS`.
##
## ### OPTIONS_DEBUG
## Additional options passed to configure during the Debug configuration. These are in addition to `OPTIONS`.
##
## ## Notes
## This command supplies many common arguments to configure. To see the full list, examine the source.
##
## ## Examples
##
## * [x264](https://github.com/Microsoft/vcpkg/blob/master/ports/x264/portfile.cmake)
## * [tcl](https://github.com/Microsoft/vcpkg/blob/master/ports/tcl/portfile.cmake)
## * [freexl](https://github.com/Microsoft/vcpkg/blob/master/ports/freexl/portfile.cmake)
## * [libosip2](https://github.com/Microsoft/vcpkg/blob/master/ports/libosip2/portfile.cmake)
macro(_vcpkg_determine_host)
    # --build: the machine you are building on
    # --host: the machine you are building for
    # --target: the machine that GCC will produce binary for
    set(HOST_ARCH $ENV{PROCESSOR_ARCHITECTURE})
    set(MINGW_W w64)
    set(MINGW_PACKAGES)
    #message(STATUS "${HOST_ARCH}")
    if(HOST_ARCH MATCHES "(amd|AMD)64")
        set(MSYS_HOST x86_64)
        set(HOST_ARCH x64)
        set(BITS 64)
        #list(APPEND MINGW_PACKAGES mingw-w64-x86_64-cccl)
    elseif(HOST_ARCH MATCHES "(x|X)86")
        set(MSYS_HOST i686)
        set(HOST_ARCH x86)
        set(BITS 32)
        #list(APPEND MINGW_PACKAGES mingw-w64-i686-cccl)
    elseif(HOST_ARCH MATCHES "^(ARM|arm)64$")
        set(MSYS_HOST arm)
        set(HOST_ARCH arm)
        set(BITS 32)
        #list(APPEND MINGW_PACKAGES mingw-w64-i686-cccl)
    elseif(HOST_ARCH MATCHES "^(ARM|arm)$")
        set(MSYS_HOST arm)
        set(HOST_ARCH arm)
        set(BITS 32)
        #list(APPEND MINGW_PACKAGES mingw-w64-i686-cccl)
        message(FATAL_ERROR "Unsupported host architecture ${HOST_ARCH} in _vcpkg_get_msys_toolchain!" )
    else()
        message(FATAL_ERROR "Unsupported host architecture ${HOST_ARCH} in _vcpkg_get_msys_toolchain!" )
    endif()
    set(TARGET_ARCH ${VCPKG_TARGET_ARCHITECTURE})
endmacro()

macro(_vcpkg_backup_env_variable envvar)
    if(ENV{${envvar}})
        set(${envvar}_BACKUP "$ENV{${envvar}}")
        set(${envvar}_PATHLIKE_CONCAT "${VCPKG_HOST_PATH_SEPARATOR}$ENV{${envvar}}")
    else()
        set(${envvar}_PATHLIKE_CONCAT)
    endif()
endmacro()

macro(_vcpkg_restore_env_variable envvar)
    if(${envvar}_BACKUP)
        set(ENV{${envvar}} ${${envvar}_BACKUP})
    else()
        unset(ENV{${envvar}})
    endif()
endmacro()


function(vcpkg_configure_make)
    cmake_parse_arguments(_csc
        "AUTOCONFIG;SKIP_CONFIGURE;COPY_SOURCE"
        "SOURCE_PATH;PROJECT_SUBPATH;PRERUN_SHELL"
        "OPTIONS;OPTIONS_DEBUG;OPTIONS_RELEASE"
        ${ARGN}
    )
    # Backup enviromnent variables
    set(C_FLAGS_BACKUP "$ENV{CFLAGS}")
    set(CXX_FLAGS_BACKUP "$ENV{CXXFLAGS}")
    set(LD_FLAGS_BACKUP "$ENV{LDFLAGS}")
    set(INCLUDE_PATH_BACKUP "$ENV{INCLUDE_PATH}")
    set(INCLUDE_BACKUP "$ENV{INCLUDE}")
    set(C_INCLUDE_PATH_BACKUP "$ENV{C_INCLUDE_PATH}")
    set(CPLUS_INCLUDE_PATH_BACKUP "$ENV{CPLUS_INCLUDE_PATH}")
    #set(LD_LIBRARY_PATH_BACKUP "$ENV{LD_LIBRARY_PATH}")
    _vcpkg_backup_env_variable(LD_LIBRARY_PATH)
    #set(LIBRARY_PATH_BACKUP "$ENV{LIBRARY_PATH}")
    _vcpkg_backup_env_variable(LIBRARY_PATH)
    set(LIBPATH_BACKUP "$ENV{LIBPATH}")

    if(${CURRENT_PACKAGES_DIR} MATCHES " " OR ${CURRENT_INSTALLED_DIR} MATCHES " ")
        # Don't bother with whitespace. The tools will probably fail and I tried very hard trying to make it work (no success so far)!
        message(WARNING "Detected whitespace in root directory. Please move the path to one without whitespaces! The required tools do not handle whitespaces correctly and the build will most likely fail")
    endif()

    # Pre-processing windows configure requirements
    if (CMAKE_HOST_WIN32)
        # YASM and PERL are not strictly required by all ports. 
        # So this should probably be moved into the portfile
        # vcpkg_find_acquire_program(YASM)
        # get_filename_component(YASM_EXE_PATH ${YASM} DIRECTORY)
        # vcpkg_add_to_path("${YASM_EXE_PATH}")

        # vcpkg_find_acquire_program(PERL)
        # get_filename_component(PERL_EXE_PATH ${PERL} DIRECTORY)
        # vcpkg_add_to_path("${PERL_EXE_PATH}")

        list(APPEND MSYS_REQUIRE_PACKAGES diffutils 
                                          pkg-config 
                                          binutils 
                                          libtool 
                                          gettext 
                                          gettext-devel
                                          make)
        if (_csc_AUTOCONFIG)
            list(APPEND MSYS_REQUIRE_PACKAGES autoconf 
                                              autoconf-archive
                                              automake
                                              m4
                )
        endif()
        vcpkg_acquire_msys(MSYS_ROOT PACKAGES ${MSYS_REQUIRE_PACKAGES})
        vcpkg_add_to_path("${MSYS_ROOT}/usr/bin")
        set(BASH "${MSYS_ROOT}/usr/bin/bash.exe")

        # This is required because PATH contains sort and find from Windows but the MSYS versions are needed
        # ${MSYS_ROOT}/urs/bin cannot be prepended to PATH due to other conflicts
        file(CREATE_LINK "${MSYS_ROOT}/usr/bin/sort.exe" "${SCRIPTS}/buildsystems/make_wrapper/sort.exe" COPY_ON_ERROR)
        file(CREATE_LINK "${MSYS_ROOT}/usr/bin/find.exe" "${SCRIPTS}/buildsystems/make_wrapper/find.exe" COPY_ON_ERROR)
        vcpkg_add_to_path(PREPEND "${SCRIPTS}/buildsystems/make_wrapper") # Other required wrappers are also located there

        # --build: the machine you are building on
        # --host: the machine you are building for
        # --target: the machine that CC will produce binaries for
        _vcpkg_determine_host() # VCPKG_HOST => machine you are building on => --build=
        if(VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
            set(BUILD_TARGET "--build=${MSYS_HOST}-pc-mingw32 --target=i686-pc-mingw32 --host=i686-pc-mingw32")
        elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
            set(BUILD_TARGET "--build=${MSYS_HOST}-pc-mingw32 --target=x86_64-pc-mingw32 --host=x86_64-pc-mingw32")
        elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL arm)
            set(BUILD_TARGET "--build=${MSYS_HOST}-pc-mingw32 --target=arm-pc-mingw32 --host=i686-pc-mingw32")
        endif()
        
        macro(_vcpkg_append_to_configure_environment inoutstring var defaultval)
            # Allows to overwrite settings in custom triplets via the enviromnent
            if(ENV{${var}})
                string(APPEND ${inoutstring} " ${var}='$ENV{${var}}'")
            else()
                string(APPEND ${inoutstring} " ${var}='${defaultval}'")
            endif()
        endmacro()

        set(CONFIGURE_ENV "")
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV CC "${MSYS_ROOT}/usr/share/automake-1.16/compile cl.exe -nologo")
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV CXX "${MSYS_ROOT}/usr/share/automake-1.16/compile cl.exe -nologo")
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV LD "link.exe -verbose")
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV AR "${MSYS_ROOT}/usr/share/automake-1.16/ar-lib lib.exe -verbose")
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV RANLIB ":") # Trick to ignore the RANLIB call
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV CCAS ":")   # If required set the ENV variable CCAS in the portfile correctly
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV NM "dumpbin.exe -symbols -headers -all") 
        # Would be better to have a true nm here! Some symbols (mainly exported variables) get not properly imported with dumpbin as nm 
        # and require __declspec(dllimport) for some reason (same problem CMake has with WINDOWS_EXPORT_ALL_SYMBOLS)
        _vcpkg_append_to_configure_environment(CONFIGURE_ENV DLLTOOL "link.exe -verbose -dll")
        
        # Other maybe interesting variables to control
        # COMPILE This is the command used to actually compile a C source file. The file name is appended to form the complete command line. 
        # LINK This is the command used to actually link a C program.
        # CXXCOMPILE The command used to actually compile a C++ source file. The file name is appended to form the complete command line. 
        # CXXLINK  The command used to actually link a C++ program. 
    
        #Some PATH handling for dealing with spaces....some tools will still fail with that!
        string(REPLACE " " "\\\ " _VCPKG_PREFIX ${CURRENT_INSTALLED_DIR})
        string(REGEX REPLACE "([a-zA-Z]):/" "/\\1/" _VCPKG_PREFIX "${_VCPKG_PREFIX}")
        set(_VCPKG_INSTALLED ${CURRENT_INSTALLED_DIR})
        string(REPLACE " " "\ " _VCPKG_INSTALLED_PKGCONF ${CURRENT_INSTALLED_DIR})
        string(REGEX REPLACE "([a-zA-Z]):/" "/\\1/" _VCPKG_INSTALLED_PKGCONF ${_VCPKG_INSTALLED_PKGCONF})
        string(REPLACE "\\" "/" _VCPKG_INSTALLED_PKGCONF ${_VCPKG_INSTALLED_PKGCONF})
        set(prefix_var "'\${prefix}'") # Windows needs extra quotes or else the variable gets expanded in the makefile!
    else()
        string(REPLACE " " "\ " _VCPKG_PREFIX ${CURRENT_INSTALLED_DIR})
        string(REPLACE " " "\ " _VCPKG_INSTALLED ${CURRENT_INSTALLED_DIR})
        set(_VCPKG_INSTALLED_PKGCONF ${CURRENT_INSTALLED_DIR})
        set(EXTRA_QUOTES)
        set(prefix_var "\${prefix}")
    endif()

    # Cleanup previous build dirs
    file(REMOVE_RECURSE "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-rel"
                        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-dbg"
                        "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}")

    set(ENV{V} "1") #Enable Verbose MODE

    # Set configure paths
    set(_csc_OPTIONS_RELEASE ${_csc_OPTIONS_RELEASE}
                            "--prefix=${EXTRA_QUOTES}${_VCPKG_PREFIX}${EXTRA_QUOTES}"
                            # Important: These should all be relative to prefix!
                            "--bindir=${prefix_var}/tools/${PORT}/bin"
                            "--sbindir=${prefix_var}/tools/${PORT}/sbin"
                            #"--libdir='\${prefix}'/lib" # already the default!
                            #"--includedir='\${prefix}'/include" # already the default!
                            "--mandir=${prefix_var}/share/${PORT}"
                            "--docdir=${prefix_var}/share/${PORT}"
                            "--datarootdir=${prefix_var}/share/${PORT}")
    set(_csc_OPTIONS_DEBUG ${_csc_OPTIONS_DEBUG}
                            "--prefix=${EXTRA_QUOTES}${_VCPKG_PREFIX}/debug${EXTRA_QUOTES}"
                            # Important: These should all be relative to prefix!
                            "--bindir=${prefix_var}/../tools/${PORT}/debug/bin"
                            "--sbindir=${prefix_var}/../tools/${PORT}/debug/sbin"
                            #"--libdir='\${prefix}'/lib" # already the default!
                            "--includedir=${prefix_var}/../include"
                            "--datarootdir=${prefix_var}/share/${PORT}")
    
    # Setup common options
    if(VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
        list(APPEND _csc_OPTIONS --disable-silent-rules --verbose --enable-shared --disable-static)
        if (VCPKG_TARGET_IS_UWP)
                list(APPEND _csc_OPTIONS --extra-ldflags=-APPCONTAINER --extra-ldflags=WindowsApp.lib)
        endif()
    else()
        list(APPEND _csc_OPTIONS --disable-silent-rules --verbose --enable-static --disable-shared)
    endif()
    
    file(RELATIVE_PATH RELATIVE_BUILD_PATH "${CURRENT_BUILDTREES_DIR}" "${_csc_SOURCE_PATH}/${_csc_PROJECT_SUBPATH}")

    set(base_cmd)
    if(CMAKE_HOST_WIN32)
        set(base_cmd ${BASH} --noprofile --norc --debug)
        # Load toolchains
        if(NOT VCPKG_CHAINLOAD_TOOLCHAIN_FILE)
            set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${SCRIPTS}/toolchains/windows.cmake")
        endif()
        include("${VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
        if(VCPKG_TARGET_IS_UWP)
            # Flags should be set in the toolchain instead
            set(ENV{LIBPATH} "$ENV{LIBPATH};$ENV{_WKITS10}references\\windows.foundation.foundationcontract\\2.0.0.0\\;$ENV{_WKITS10}references\\windows.foundation.universalapicontract\\3.0.0.0\\")
            set(_csc_OPTIONS ${_csc_OPTIONS} --extra-cflags=-DWINAPI_FAMILY=WINAPI_FAMILY_APP --extra-cflags=-D_WIN32_WINNT=0x0A00)
        endif()
        #Join the options list as a string with spaces between options
        list(JOIN _csc_OPTIONS " " _csc_OPTIONS)
        list(JOIN _csc_OPTIONS_RELEASE " " _csc_OPTIONS_RELEASE)
        list(JOIN _csc_OPTIONS_DEBUG " " _csc_OPTIONS_DEBUG)
    endif()
    
    # Setup include enviromnent
    set(ENV{INCLUDE} "${_VCPKG_INSTALLED}/include${VCPKG_HOST_PATH_SEPARATOR}${INCLUDE_BACKUP}")
    set(ENV{INCLUDE_PATH} "${_VCPKG_INSTALLED}/include${VCPKG_HOST_PATH_SEPARATOR}${INCLUDE_PATH_BACKUP}")
    set(ENV{C_INCLUDE_PATH} "${_VCPKG_INSTALLED}/include${VCPKG_HOST_PATH_SEPARATOR}${C_INCLUDE_PATH_BACKUP}")
    set(ENV{CPLUS_INCLUDE_PATH} "${_VCPKG_INSTALLED}/include${VCPKG_HOST_PATH_SEPARATOR}${CPLUS_INCLUDE_PATH_BACKUP}")

    # Setup global flags -> TODO: Further improve with toolchain file in mind!
    set(C_FLAGS_GLOBAL "$ENV{CFLAGS} ${VCPKG_C_FLAGS}")
    set(CXX_FLAGS_GLOBAL "$ENV{CXXFLAGS} ${VCPKG_CXX_FLAGS}")
    set(LD_FLAGS_GLOBAL "$ENV{LDFLAGS} ${VCPKG_LINKER_FLAGS}")
    # Flags should be set in the toolchain instead
    if(NOT VCPKG_TARGET_IS_WINDOWS)
        string(APPEND C_FLAGS_GLOBAL " -fPIC")
        string(APPEND CXX_FLAGS_GLOBAL " -fPIC")
    else()
        string(APPEND C_FLAGS_GLOBAL " /D_WIN32_WINNT=0x0601 /DWIN32_LEAN_AND_MEAN /DWIN32 /D_WINDOWS")
        string(APPEND CXX_FLAGS_GLOBAL " /D_WIN32_WINNT=0x0601 /DWIN32_LEAN_AND_MEAN /DWIN32 /D_WINDOWS")
        string(APPEND LD_FLAGS_GLOBAL " /VERBOSE -no-undefined")
        if(VCPKG_TARGET_ARCHITECTURE STREQUAL x64)
            string(APPEND LD_FLAGS_GLOBAL " /machine:x64")
        elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
            string(APPEND LD_FLAGS_GLOBAL " /machine:x86")
        endif()
    endif()
    
    if(NOT ENV{PKG_CONFIG})
        find_program(PKGCONFIG pkg-config PATHS "${MSYS_ROOT}/usr/bin" REQUIRED)
        debug_message("Using pkg-config from: ${PKGCONFIG}")
        if(NOT PKGCONFIG)
            message(STATUS "${PORT} requires pkg-config from the system package manager (example: \"sudo apt-get install pkg-config\")")
        endif()
    else()
        debug_message("ENV{PKG_CONFIG} found! Using: $ENV{PKG_CONFIG}")
        set(PKGCONFIG $ENV{PKG_CONFIG})
    endif()
    
    set(SRC_DIR "${_csc_SOURCE_PATH}/${_csc_PROJECT_SUBPATH}")

    # Run autoconf if necessary
    if(EXISTS "${SRC_DIR}/configure" AND NOT _csc_SKIP_CONFIGURE)
        set(REQUIRES_AUTOCONFIG FALSE) # use autotools and configure.ac
        set(REQUIRES_AUTOGEN FALSE) # use autogen.sh
    elseif(EXISTS "${SRC_DIR}/configure.ac")
        set(REQUIRES_AUTOCONFIG TRUE)
        set(REQUIRES_AUTOGEN FALSE)
    elseif(EXISTS "${SRC_DIR}/autogen.sh")
        set(REQUIRES_AUTOGEN TRUE)
        set(REQUIRES_AUTOCONFIG FALSE)
    endif()
    set(_GENERATED_CONFIGURE FALSE)
    if (_csc_AUTOCONFIG OR REQUIRES_AUTOCONFIG)
        find_program(AUTORECONF autoreconf REQUIRED)
        if(NOT AUTORECONF)
            message(STATUS "${PORT} requires autoconf from the system package manager (example: \"sudo apt-get install autoconf\")")
        endif()
        find_program(LIBTOOL libtool REQUIRED)
        if(NOT LIBTOOL)
            message(STATUS "${PORT} requires libtool from the system package manager (example: \"sudo apt-get install libtool libtool-bin\")")
        endif()
        find_program(AUTOPOINT autopoint REQUIRED)
        if(NOT AUTOPOINT)
            message(STATUS "${PORT} requires autopoint from the system package manager (example: \"sudo apt-get install autopoint\")")
        endif()
        message(STATUS "Generating configure for ${TARGET_TRIPLET}")
        if (CMAKE_HOST_WIN32)
            vcpkg_execute_required_process(
                COMMAND ${base_cmd} -c "autoreconf -vfi"
                WORKING_DIRECTORY "${SRC_DIR}"
                LOGNAME autoconf-${TARGET_TRIPLET}
            )
        else()
            vcpkg_execute_required_process(
                COMMAND autoreconf -vfi
                WORKING_DIRECTORY "${SRC_DIR}"
                LOGNAME autoconf-${TARGET_TRIPLET}
            )
        endif()
        message(STATUS "Finished generating configure for ${TARGET_TRIPLET}")
    endif()
    if(REQUIRES_AUTOGEN)
        message(STATUS "Generating configure for ${TARGET_TRIPLET} via autogen.sh")
        if (CMAKE_HOST_WIN32)
            vcpkg_execute_required_process(
                COMMAND ${base_cmd} -c "./autogen.sh"
                WORKING_DIRECTORY "${SRC_DIR}"
                LOGNAME autoconf-${TARGET_TRIPLET}
            )
        else()
            vcpkg_execute_required_process(
                COMMAND "./autogen.sh"
                WORKING_DIRECTORY "${SRC_DIR}"
                LOGNAME autoconf-${TARGET_TRIPLET}
            )
        endif()
        message(STATUS "Finished generating configure for ${TARGET_TRIPLET}")
    endif()

    if (_csc_PRERUN_SHELL)
        message(STATUS "Prerun shell with ${TARGET_TRIPLET}")
        vcpkg_execute_required_process(
            COMMAND ${base_cmd} -c "${_csc_PRERUN_SHELL}"
            WORKING_DIRECTORY "${SRC_DIR}"
            LOGNAME prerun-${TARGET_TRIPLET}
        )
    endif()

    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug" AND NOT _csc_NO_DEBUG)
        set(_VAR_SUFFIX DEBUG)
        set(PATH_SUFFIX_${_VAR_SUFFIX} "/debug")
        set(SHORT_NAME_${_VAR_SUFFIX} "dbg")
        list(APPEND _buildtypes ${_VAR_SUFFIX})
        if (CMAKE_HOST_WIN32) # Flags should be set in the toolchain instead
            string(REGEX REPLACE "[ \t]+/" " -" CFLAGS_${_VAR_SUFFIX} "${C_FLAGS_GLOBAL} ${VCPKG_CRT_LINK_FLAG_PREFIX}d /D_DEBUG /Ob0 /Od ${VCPKG_C_FLAGS_${_VAR_SUFFIX}}")
            string(REGEX REPLACE "[ \t]+/" " -" CXXFLAGS_${_VAR_SUFFIX} "${CXX_FLAGS_GLOBAL} ${VCPKG_CRT_LINK_FLAG_PREFIX}d /D_DEBUG /Ob0 /Od ${VCPKG_CXX_FLAGS_${_VAR_SUFFIX}}")
            string(REGEX REPLACE "[ \t]+/" " -" LDFLAGS_${_VAR_SUFFIX} "-L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib ${LD_FLAGS_GLOBAL} ${VCPKG_LINKER_FLAGS_${_VAR_SUFFIX}}")
        else()
            set(CFLAGS_${_VAR_SUFFIX} "${C_FLAGS_GLOBAL} ${VCPKG_C_FLAGS_DEBUG}")
            set(CXXFLAGS_${_VAR_SUFFIX} "${CXX_FLAGS_GLOBAL} ${VCPKG_CXX_FLAGS_DEBUG}")
            set(LDFLAGS_${_VAR_SUFFIX} "-L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib/ -L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib/manual-link/ ${LD_FLAGS_GLOBAL} ${VCPKG_LINKER_FLAGS_${_VAR_SUFFIX}}")
        endif()
        unset(_VAR_SUFFIX)
    endif()
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
        set(_VAR_SUFFIX RELEASE)
        set(PATH_SUFFIX_${_VAR_SUFFIX} "")
        set(SHORT_NAME_${_VAR_SUFFIX} "rel")
        list(APPEND _buildtypes ${_VAR_SUFFIX})
        if (CMAKE_HOST_WIN32) # Flags should be set in the toolchain instead
            string(REGEX REPLACE "[ \t]+/" " -" CFLAGS_${_VAR_SUFFIX} "${C_FLAGS_GLOBAL} ${VCPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${VCPKG_C_FLAGS_${_VAR_SUFFIX}}")
            string(REGEX REPLACE "[ \t]+/" " -" CXXFLAGS_${_VAR_SUFFIX} "${CXX_FLAGS_GLOBAL} ${VCPKG_CRT_LINK_FLAG_PREFIX} /O2 /Oi /Gy /DNDEBUG ${VCPKG_CXX_FLAGS_${_VAR_SUFFIX}}")
            string(REGEX REPLACE "[ \t]+/" " -" LDFLAGS_${_VAR_SUFFIX} "-L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib ${LD_FLAGS_GLOBAL} ${VCPKG_LINKER_FLAGS_${_VAR_SUFFIX}}")
        else()
            set(CFLAGS_${_VAR_SUFFIX} "${C_FLAGS_GLOBAL} ${VCPKG_C_FLAGS_DEBUG}")
            set(CXXFLAGS_${_VAR_SUFFIX} "${CXX_FLAGS_GLOBAL} ${VCPKG_CXX_FLAGS_DEBUG}")
            set(LDFLAGS_${_VAR_SUFFIX} "-L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib/ -L${_VCPKG_INSTALLED}${PATH_SUFFIX_${_VAR_SUFFIX}}/lib/manual-link/ ${LD_FLAGS_GLOBAL} ${VCPKG_LINKER_FLAGS_${_VAR_SUFFIX}}")
        endif()
        unset(_VAR_SUFFIX)
    endif()

    foreach(_buildtype IN LISTS _buildtypes)
        set(TAR_DIR "${CURRENT_BUILDTREES_DIR}/${TARGET_TRIPLET}-${SHORT_NAME_${_buildtype}}")
        file(MAKE_DIRECTORY "${TAR_DIR}")
        file(RELATIVE_PATH RELATIVE_BUILD_PATH "${TAR_DIR}" "${SRC_DIR}")

        if(_csc_COPY_SOURCE)
            file(COPY "${SRC_DIR}/" DESTINATION "${TAR_DIR}")
            set(RELATIVE_BUILD_PATH .)
        endif()

        set(PKGCONFIG_INSTALLED_DIR "${_VCPKG_INSTALLED_PKGCONF}${PATH_SUFFIX_${_buildtype}}/lib/pkgconfig")
        set(PKGCONFIG_INSTALLED_SHARE_DIR "${_VCPKG_INSTALLED_PKGCONF}/share/pkgconfig")

        if(ENV{PKG_CONFIG_PATH})
            set(BACKUP_ENV_PKG_CONFIG_PATH_${_buildtype} $ENV{PKG_CONFIG_PATH})
            set(ENV{PKG_CONFIG_PATH} "${PKGCONFIG_INSTALLED_DIR}:${PKGCONFIG_INSTALLED_SHARE_DIR}:$ENV{PKG_CONFIG_PATH}")
        else()
            set(ENV{PKG_CONFIG_PATH} "${PKGCONFIG_INSTALLED_DIR}:${PKGCONFIG_INSTALLED_SHARE_DIR}")
        endif()

        # Setup enviromnent
        set(ENV{CFLAGS} ${CFLAGS_${_buildtype}})
        set(ENV{CXXFLAGS} ${CXXFLAGS_${_buildtype}})
        set(ENV{LDFLAGS} ${LDFLAGS_${_buildtype}})
        set(ENV{PKG_CONFIG} "${PKGCONFIG} --define-variable=prefix=${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}")
        set(ENV{LIBPATH} "${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}/lib${VCPKG_HOST_PATH_SEPARATOR}${LIBPATH_BACKUP}")
 
        set(ENV{LIBRARY_PATH} "${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}/lib/${VCPKG_HOST_PATH_SEPARATOR}${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}/lib/manual-link/${LD_LIBRARY_PATH_PATHLIKE_CONCAT}")
        set(ENV{LD_LIBRARY_PATH} "${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}/lib/${VCPKG_HOST_PATH_SEPARATOR}${_VCPKG_INSTALLED}${PATH_SUFFIX_${_buildtype}}/lib/manual-link/${LD_LIBRARY_PATH_PATHLIKE_CONCAT}")

        if (CMAKE_HOST_WIN32)   
            set(command ${base_cmd} -c "${CONFIGURE_ENV} ./${RELATIVE_BUILD_PATH}/configure ${BUILD_TARGET} ${HOST_TYPE}${_csc_OPTIONS} ${_csc_OPTIONS_${_buildtype}}")
        else()
            set(command /bin/bash "./${RELATIVE_BUILD_PATH}/configure" ${_csc_OPTIONS} ${_csc_OPTIONS_${_buildtype}})
        endif()

        if (NOT _csc_SKIP_CONFIGURE)
            message(STATUS "Configuring ${TARGET_TRIPLET}-${SHORT_NAME_${_buildtype}}")
            vcpkg_execute_required_process(
                COMMAND ${command}
                WORKING_DIRECTORY "${TAR_DIR}"
                LOGNAME config-${TARGET_TRIPLET}-${SHORT_NAME_${_buildtype}}
            )
            if(EXISTS "${TAR_DIR}/libtool" AND VCPKG_TARGET_IS_WINDOWS AND VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
                set(_file "${TAR_DIR}/libtool")
                file(READ "${_file}" _contents)
                string(REPLACE ".dll.lib" ".lib" _contents "${_contents}")
                file(WRITE "${_file}" "${_contents}")
            endif()
        endif()

        if(BACKUP_ENV_PKG_CONFIG_PATH_${_buildtype})
            set(ENV{PKG_CONFIG_PATH} "${BACKUP_ENV_PKG_CONFIG_PATH_${_buildtype}}")
        else()
            unset(ENV{PKG_CONFIG_PATH})
        endif()
        unset(BACKUP_ENV_PKG_CONFIG_PATH_${_buildtype})
    endforeach()
        
    # Restore enviromnent
    set(ENV{CFLAGS} "${C_FLAGS_BACKUP}")
    set(ENV{CXXFLAGS} "${CXX_FLAGS_BACKUP}")
    set(ENV{LDFLAGS} "${LD_FLAGS_BACKUP}")

    set(ENV{INCLUDE} "${INCLUDE_BACKUP}")
    set(ENV{INCLUDE_PATH} "${INCLUDE_PATH_BACKUP}")
    set(ENV{C_INCLUDE_PATH} "${C_INCLUDE_PATH_BACKUP}")
    set(ENV{CPLUS_INCLUDE_PATH} "${CPLUS_INCLUDE_PATH_BACKUP}")
    _vcpkg_restore_env_variable(LIBRARY_PATH)
    _vcpkg_restore_env_variable(LD_LIBRARY_PATH)
    set(ENV{LIBPATH} "${LIBPATH_BACKUP}")
    SET(_VCPKG_PROJECT_SOURCE_PATH ${_csc_SOURCE_PATH} PARENT_SCOPE)
    set(_VCPKG_PROJECT_SUBPATH ${_csc_PROJECT_SUBPATH} PARENT_SCOPE)
endfunction()
