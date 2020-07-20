## # vcpkg_find_acquire_program
##
## Download or find a well-known tool.
##
## ## Usage
## ```cmake
## vcpkg_find_acquire_program(<VAR>)
## ```
## ## Parameters
## ### VAR
## This variable specifies both the program to be acquired as well as the out parameter that will be set to the path of the program executable.
##
## ## Notes
## The current list of programs includes:
##
## - 7Z
## - ARIA2 (Downloader)
## - BISON
## - DARK
## - DOXYGEN
## - FLEX
## - GASPREPROCESSOR
## - GPERF
## - PERL
## - PYTHON2
## - PYTHON3
## - GIT
## - GN
## - GO
## - JOM
## - MESON
## - NASM
## - NINJA
## - NUGET
## - SCONS
## - YASM
##
## Note that msys2 has a dedicated helper function: [`vcpkg_acquire_msys`](vcpkg_acquire_msys.md).
##
## ## Examples
##
## * [ffmpeg](https://github.com/Microsoft/vcpkg/blob/master/ports/ffmpeg/portfile.cmake)
## * [openssl](https://github.com/Microsoft/vcpkg/blob/master/ports/openssl/portfile.cmake)
## * [qt5](https://github.com/Microsoft/vcpkg/blob/master/ports/qt5/portfile.cmake)
function(vcpkg_find_acquire_program VAR)
  set(EXPANDED_VAR ${${VAR}})
  if(EXPANDED_VAR)
    return()
  endif()

  unset(NOEXTRACT)
  unset(_vfa_RENAME)
  unset(SUBDIR)
  unset(REQUIRED_INTERPRETER)
  unset(_vfa_SUPPORTED)
  unset(POST_INSTALL_COMMAND)

  vcpkg_get_program_files_platform_bitness(PROGRAM_FILES_PLATFORM_BITNESS)
  set(PROGRAM_FILES_32_BIT $ENV{ProgramFiles\(X86\)})
  if (NOT DEFINED PROGRAM_FILES_32_BIT)
      set(PROGRAM_FILES_32_BIT $ENV{PROGRAMFILES})
  endif()

  if(VAR MATCHES "PERL")
    set(PROGNAME perl)
    set(PATHS ${DOWNLOADS}/tools/perl/perl/bin)
    set(BREW_PACKAGE_NAME "perl")
    set(APT_PACKAGE_NAME "perl")
    set(URL 
      "https://strawberry.perl.bot/download/5.30.0.1/strawberry-perl-5.30.0.1-32bit.zip"
      "http://strawberryperl.com/download/5.30.0.1/strawberry-perl-5.30.0.1-32bit.zip"
    )
    set(ARCHIVE "strawberry-perl-5.30.0.1-32bit.zip")
    set(HASH d353d3dc743ebdc6d1e9f6f2b7a6db3c387c1ce6c890bae8adc8ae5deae8404f4c5e3cf249d1e151e7256d4c5ee9cd317e6c41f3b6f244340de18a24b938e0c4)
  elseif(VAR MATCHES "NASM")
    set(PROGNAME nasm)
    set(PATHS ${DOWNLOADS}/tools/nasm/nasm-2.14.02)
    set(BREW_PACKAGE_NAME "nasm")
    set(APT_PACKAGE_NAME "nasm")
    set(URL
      "http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/win32/nasm-2.14.02-win32.zip"
      "http://fossies.org/windows/misc/nasm-2.14.02-win32.zip"
    )
    set(ARCHIVE "nasm-2.14.02-win32.zip")
    set(HASH a0f16a9f3b668b086e3c4e23a33ff725998e120f2e3ccac8c28293fd4faeae6fc59398919e1b89eed7461685d2730de02f2eb83e321f73609f35bf6b17a23d1e)
  elseif(VAR MATCHES "YASM")
    set(PROGNAME yasm)
    set(SUBDIR 1.3.0.6)
    set(PATHS ${DOWNLOADS}/tools/yasm/${SUBDIR})
    set(BREW_PACKAGE_NAME "yasm")
    set(APT_PACKAGE_NAME "yasm")
    set(URL "https://www.tortall.net/projects/yasm/snapshots/v1.3.0.6.g1962/yasm-1.3.0.6.g1962.exe")
    set(ARCHIVE "yasm-1.3.0.6.g1962.exe")
    set(_vfa_RENAME "yasm.exe")
    set(NOEXTRACT ON)
    set(HASH c1945669d983b632a10c5ff31e86d6ecbff143c3d8b2c433c0d3d18f84356d2b351f71ac05fd44e5403651b00c31db0d14615d7f9a6ecce5750438d37105c55b)
  elseif(VAR MATCHES "GIT")
    set(PROGNAME git)
    if(CMAKE_HOST_WIN32)
      set(SUBDIR "git-2.26.2-1-windows")
      set(URL "https://github.com/git-for-windows/git/releases/download/v2.26.2.windows.1/PortableGit-2.26.2-32-bit.7z.exe")
      set(ARCHIVE "PortableGit-2.26.2-32-bit.7z.exe")
      set(HASH d3cb60d62ca7b5d05ab7fbed0fa7567bec951984568a6c1646842a798c4aaff74bf534cf79414a6275c1927081a11b541d09931c017bf304579746e24fe57b36)
      set(PATHS 
        "${DOWNLOADS}/tools/${SUBDIR}/mingw32/bin"
        "${DOWNLOADS}/tools/git/${SUBDIR}/mingw32/bin")
    else()
      set(BREW_PACKAGE_NAME "git")
      set(APT_PACKAGE_NAME "git")
    endif()
  elseif(VAR MATCHES "GN")
    set(PROGNAME gn)
    set(_vfa_RENAME "gn")
    set(CIPD_DOWNLOAD_GN "https://chrome-infra-packages.appspot.com/dl/gn/gn")
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
      set(_vfa_SUPPORTED ON)
      set(GN_VERSION "xus7xtaPhpv5vCmKFOnsBVoB-PKmhZvRsSTjbQAuF0MC")
      set(GN_PLATFORM "linux-amd64")
      set(HASH "871e75d7f3597b74fb99e36bb41fe5a9f8ce8a4d9f167f4729fc6e444807a59f35ec8aca70c2274a99c79d70a1108272be1ad991678a8ceb39e30f77abb13135")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
      set(_vfa_SUPPORTED ON)
      set(GN_VERSION "qhxILDNcJ2H44HfHmfiU-XIY3E_SIXvFqLd2wvbIgOoC")
      set(GN_PLATFORM "mac-amd64")
      set(HASH "03ee64cb15bae7fceb412900d470601090bce147cfd45eb9b46683ac1a5dca848465a5d74c55a47df7f0e334d708151249a6d37bb021de74dd48b97ed4a07937")
    else()
      set(GN_VERSION "qUkAhy9J0P7c5racy-9wB6AHNK_btS18im8S06_ehhwC")
      set(GN_PLATFORM "windows-amd64")
      set(HASH "263e02bd79eee0cb7b664831b7898565c5656a046328d8f187ef7ae2a4d766991d477b190c9b425fcc960ab76f381cd3e396afb85cba7408ca9e74eb32c175db")
    endif()
    set(SUBDIR "${GN_VERSION}")
    set(PATHS "${DOWNLOADS}/tools/gn/${SUBDIR}")
    set(URL "${CIPD_DOWNLOAD_GN}/${GN_PLATFORM}/+/${GN_VERSION}")
    set(ARCHIVE "gn-${GN_PLATFORM}.zip")
  elseif(VAR MATCHES "GO")
    set(PROGNAME go)
    set(PATHS ${DOWNLOADS}/tools/go/go/bin)
    set(BREW_PACKAGE_NAME "go")
    set(APT_PACKAGE_NAME "golang-go")
    set(URL "https://dl.google.com/go/go1.13.1.windows-386.zip")
    set(ARCHIVE "go1.13.1.windows-386.zip")
    set(HASH 2ab0f07e876ad98d592351a8808c2de42351ab387217e088bc4c5fa51d6a835694c501e2350802323b55a27dc0157f8b70045597f789f9e50f5ceae50dea3027)
  elseif(VAR MATCHES "PYTHON3")
    if(CMAKE_HOST_WIN32)
      set(PROGNAME python)
      if (VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
        set(SUBDIR "python-3.8.3-x86")
        set(URL "https://www.python.org/ftp/python/3.8.3/python-3.8.3-embed-win32.zip")
        set(ARCHIVE "python-3.8.3-embed-win32.zip")
        set(HASH 8c9078f55b1b5d694e0e809eee6ccf8a6e15810dd4649e8ae1209bff30e102d49546ce970a5d519349ca7759d93146f459c316dc440737171f018600255dcd0a)
      else()
        set(SUBDIR "python-3.8.3-x64")
        set(URL "https://www.python.org/ftp/python/3.8.3/python-3.8.3-embed-amd64.zip")
        set(ARCHIVE "python-3.8.3-embed-amd64.zip")
        set(HASH a322fc925167edb1897764297cf47e294ad3f52c109a05f8911412807eb83e104f780e9fe783b17fe0d9b18b7838797c15e9b0805dab759829f77a9bc0159424)
      endif()
      set(PATHS ${DOWNLOADS}/tools/python/${SUBDIR})
      set(POST_INSTALL_COMMAND ${CMAKE_COMMAND} -E remove python38._pth)
    else()
      set(PROGNAME python3)
      set(BREW_PACKAGE_NAME "python")
      set(APT_PACKAGE_NAME "python3")
    endif()
  elseif(VAR MATCHES "PYTHON2")
    if(CMAKE_HOST_WIN32)
      set(PROGNAME python)
      if (VCPKG_TARGET_ARCHITECTURE STREQUAL x86)
        set(SUBDIR "python-2.7.16-x86")
        set(URL "https://www.python.org/ftp/python/2.7.16/python-2.7.16.msi")
        set(ARCHIVE "python-2.7.16.msi")
        set(HASH c34a6fa2438682104dccb53650a2bdb79eac7996deff075201a0f71bb835d60d3ed866652a1931f15a29510fe8e1009ac04e423b285122d2e5747fefc4c10254)
      else()
        set(SUBDIR "python-2.7.16-x64")
        set(URL "https://www.python.org/ftp/python/2.7.16/python-2.7.16.amd64.msi")
        set(ARCHIVE "python-2.7.16.amd64.msi")
        set(HASH 47c1518d1da939e3ba6722c54747778b93a44c525bcb358b253c23b2510374a49a43739c8d0454cedade858f54efa6319763ba33316fdc721305bc457efe4ffb)
      endif()
      set(PATHS ${DOWNLOADS}/tools/python/${SUBDIR})
    else()
      set(PROGNAME python2)
      set(BREW_PACKAGE_NAME "python2")
      set(APT_PACKAGE_NAME "python")
    endif()
  elseif(VAR MATCHES "RUBY")
    set(PROGNAME "ruby")
    set(PATHS ${DOWNLOADS}/tools/ruby/rubyinstaller-2.6.3-1-x86/bin)
    set(URL https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.6.3-1/rubyinstaller-2.6.3-1-x86.7z)
    set(ARCHIVE rubyinstaller-2.6.3-1-x86.7z)
    set(HASH 4322317dd02ce13527bf09d6e6a7787ca3814ea04337107d28af1ac360bd272504b32e20ed3ea84eb5b21dae7b23bfe5eb0e529b6b0aa21a1a2bbb0a542d7aec)
  elseif(VAR MATCHES "JOM")
    set(PROGNAME jom)
    set(SUBDIR "jom-1.1.3")
    set(PATHS ${DOWNLOADS}/tools/jom/${SUBDIR})
    set(URL 
      "http://download.qt.io/official_releases/jom/jom_1_1_3.zip" 
      "http://mirrors.ocf.berkeley.edu/qt/official_releases/jom/jom_1_1_3.zip"
    )
    set(ARCHIVE "jom_1_1_3.zip")
    set(HASH 5b158ead86be4eb3a6780928d9163f8562372f30bde051d8c281d81027b766119a6e9241166b91de0aa6146836cea77e5121290e62e31b7a959407840fc57b33)
  elseif(VAR MATCHES "7Z")
    set(PROGNAME 7z)
    set(PATHS "${PROGRAM_FILES_PLATFORM_BITNESS}/7-Zip" "${PROGRAM_FILES_32_BIT}/7-Zip" "${DOWNLOADS}/tools/7z/Files/7-Zip")
    set(URL "https://7-zip.org/a/7z1900.msi")
    set(ARCHIVE "7z1900.msi")
    set(HASH f73b04e2d9f29d4393fde572dcf3c3f0f6fa27e747e5df292294ab7536ae24c239bf917689d71eb10cc49f6b9a4ace26d7c122ee887d93cc935f268c404e9067)
  elseif(VAR MATCHES "NINJA")
    set(PROGNAME ninja)
    set(SUBDIR "ninja-1.10.0")
    if(CMAKE_HOST_WIN32)
      set(PATHS "${DOWNLOADS}/tools/${SUBDIR}-windows")
      list(APPEND PATHS "${DOWNLOADS}/tools/ninja/${SUBDIR}")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
      set(PATHS "${DOWNLOADS}/tools/${SUBDIR}-osx")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "FreeBSD")
      set(PATHS "${DOWNLOADS}/tools/${SUBDIR}-freebsd")
    else()
      set(PATHS "${DOWNLOADS}/tools/${SUBDIR}-linux")
    endif()
    set(BREW_PACKAGE_NAME "ninja")
    set(APT_PACKAGE_NAME "ninja-build")
    set(URL "https://github.com/ninja-build/ninja/releases/download/v1.10.0/ninja-win.zip")
    set(ARCHIVE "ninja-win-1.10.0.zip")
    set(HASH a196e243c53daa1df9d287af658d6d38d6b830b614f2d5704e8c88ffc61f179a533ae71cdb6d0d383d1559d65dacccbaaab270fb2a33aa211e5dba42ff046f97)
  elseif(VAR MATCHES "NUGET")
    set(PROGNAME nuget)
    set(SUBDIR "5.5.1")
    set(PATHS "${DOWNLOADS}/tools/nuget/${SUBDIR}")
    set(BREW_PACKAGE_NAME "nuget")
    set(URL "https://dist.nuget.org/win-x86-commandline/v5.5.1/nuget.exe")
    set(_vfa_RENAME "nuget.exe")
    set(ARCHIVE "nuget.5.5.1.exe")
    set(NOEXTRACT ON)
    set(HASH 22ea847d8017cd977664d0b13c889cfb13c89143212899a511be217345a4e243d4d8d4099700114a11d26a087e83eb1a3e2b03bdb5e0db48f10403184cd26619)
  elseif(VAR MATCHES "MESON")
    set(PROGNAME meson)
    set(REQUIRED_INTERPRETER PYTHON3)
    set(BREW_PACKAGE_NAME "meson")
    set(APT_PACKAGE_NAME "meson")
    if(CMAKE_HOST_WIN32)
      set(SCRIPTNAME meson.py)
    else()
      set(SCRIPTNAME meson)
    endif()
    set(PATHS ${DOWNLOADS}/tools/meson/meson-0.54.2)
    set(URL "https://github.com/mesonbuild/meson/archive/0.54.2.zip")
    set(ARCHIVE "meson-0.54.2.zip")
    set(HASH 8d19110bad3e6a223d1d169e833b746b884ece9cd23d2539ec02dccb5cd0c56542414b7afc0f7f2adcec9d957e4120d31f41734397aa0a7ee7f9c29ebdc9eb4c)
  elseif(VAR MATCHES "FLEX" OR VAR MATCHES "BISON")
    if(CMAKE_HOST_WIN32)
      set(SOURCEFORGE_ARGS
        REPO winflexbison
        FILENAME winflexbison-2.5.16.zip
        SHA512 0a14154bff5d998feb23903c46961528f8ccb4464375d5384db8c4a7d230c0c599da9b68e7a32f3217a0a0735742242eaf3769cb4f03e00931af8640250e9123
        NO_REMOVE_ONE_LEVEL
        WORKING_DIRECTORY "${DOWNLOADS}/tools/winflexbison"
      )
      if(VAR MATCHES "FLEX")
        set(PROGNAME win_flex)
      else()
        set(PROGNAME win_bison)
      endif()
      set(PATHS ${DOWNLOADS}/tools/winflexbison/0a14154bff-a8cf65db07)
      if(NOT EXISTS "${PATHS}/data/m4sugar/m4sugar.m4")
        file(REMOVE_RECURSE "${PATHS}")
      endif()
    elseif(VAR MATCHES "FLEX")
      set(PROGNAME flex)
      set(APT_PACKAGE_NAME flex)
      set(BREW_PACKAGE_NAME flex)
    else()
      set(PROGNAME bison)
      set(APT_PACKAGE_NAME bison)
      set(BREW_PACKAGE_NAME bison)
      if (APPLE)
        set(PATHS /usr/local/opt/bison/bin)
      endif()
    endif()
  elseif(VAR MATCHES "GPERF")
    set(PROGNAME gperf)
    set(PATHS ${DOWNLOADS}/tools/gperf/bin)
    set(URL "https://sourceforge.net/projects/gnuwin32/files/gperf/3.0.1/gperf-3.0.1-bin.zip/download")
    set(ARCHIVE "gperf-3.0.1-bin.zip")
    set(HASH 3f2d3418304390ecd729b85f65240a9e4d204b218345f82ea466ca3d7467789f43d0d2129fcffc18eaad3513f49963e79775b10cc223979540fa2e502fe7d4d9)
  elseif(VAR MATCHES "GASPREPROCESSOR")
    set(NOEXTRACT true)
    set(PROGNAME gas-preprocessor)
    set(SUBDIR "b5ea3a50")
    set(REQUIRED_INTERPRETER PERL)
    set(SCRIPTNAME "gas-preprocessor.pl")
    set(PATHS ${DOWNLOADS}/tools/gas-preprocessor/${SUBDIR})
    set(_vfa_RENAME "gas-preprocessor.pl")
    set(URL "https://raw.githubusercontent.com/FFmpeg/gas-preprocessor/b5ea3a50ed991e6a3218e89402a8162c73f59cb2/gas-preprocessor.pl")
    set(ARCHIVE "gas-preprocessor-${SUBDIR}.pl")
    set(HASH 3a42a90dee09f3c8653d043d848057287f7460806a08f9471131d0c546ba541bdfa4efa3019e7ffc57a6c20538f1034f7a53b30ecaad9db5add7c71d8de35db9)
  elseif(VAR MATCHES "DARK")
    set(PROGNAME dark)
    set(SUBDIR "wix311-binaries")
    set(PATHS ${DOWNLOADS}/tools/dark/${SUBDIR})
    set(URL "https://github.com/wixtoolset/wix3/releases/download/wix311rtm/wix311-binaries.zip")
    set(ARCHIVE "wix311-binaries.zip")
    set(HASH 74f0fa29b5991ca655e34a9d1000d47d4272e071113fada86727ee943d913177ae96dc3d435eaf494d2158f37560cd4c2c5274176946ebdb17bf2354ced1c516)
  elseif(VAR MATCHES "SCONS")
    set(PROGNAME scons)
    set(REQUIRED_INTERPRETER PYTHON2)
    set(SCRIPTNAME "scons.py")
    set(PATHS ${DOWNLOADS}/tools/scons)
    set(URL "https://sourceforge.net/projects/scons/files/scons-local-3.0.1.zip/download")
    set(ARCHIVE "scons-local-3.0.1.zip")
    set(HASH fe121b67b979a4e9580c7f62cfdbe0c243eba62a05b560d6d513ac7f35816d439b26d92fc2d7b7d7241c9ce2a49ea7949455a17587ef53c04a5f5125ac635727)
  elseif(VAR MATCHES "DOXYGEN")
    set(PROGNAME doxygen)
    set(DOXYGEN_VERSION 1.8.17)
    set(PATHS ${DOWNLOADS}/tools/doxygen)
    set(URL
      "http://doxygen.nl/files/doxygen-${DOXYGEN_VERSION}.windows.bin.zip"
      "https://sourceforge.net/projects/doxygen/files/rel-${DOXYGEN_VERSION}/doxygen-${DOXYGEN_VERSION}.windows.bin.zip")
    set(ARCHIVE "doxygen-${DOXYGEN_VERSION}.windows.bin.zip")
    set(HASH 6bac47ec552486783a70cc73b44cf86b4ceda12aba6b52835c2221712bd0a6c845cecec178c9ddaa88237f5a781f797add528f47e4ed017c7888eb1dd2bc0b4b)
  elseif(VAR MATCHES "BAZEL")
    set(PROGNAME bazel)
    set(BAZEL_VERSION 0.25.2)
    set(SUBDIR ${BAZEL_VERSION})
    set(PATHS ${DOWNLOADS}/tools/bazel/${SUBDIR})
    set(_vfa_RENAME "bazel")
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
      set(_vfa_SUPPORTED ON)
      set(URL "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64")
      set(ARCHIVE "bazel-${BAZEL_VERSION}-linux-x86_64")
      set(NOEXTRACT ON)
      set(HASH db4a583cf2996aeb29fd008261b12fe39a4a5faf0fbf96f7124e6d3ffeccf6d9655d391378e68dd0915bc91c9e146a51fd9661963743857ca25179547feceab1)
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
      set(_vfa_SUPPORTED ON)
      set(URL "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-darwin-x86_64") 
      set(ARCHIVE "bazel-${BAZEL_VERSION}-darwin-x86_64")
      set(NOEXTRACT ON)
      set(HASH 420a37081e6ee76441b0d92ff26d1715ce647737ce888877980d0665197b5a619d6afe6102f2e7edfb5062c9b40630a10b2539585e35479b780074ada978d23c)
    else()
      set(URL "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-windows-x86_64.zip") 
      set(ARCHIVE "bazel-${BAZEL_VERSION}-windows-x86_64.zip")
      set(HASH 6482f99a0896f55ef65739e7b53452fd9c0adf597b599d0022a5e0c5fa4374f4a958d46f98e8ba25af4b065adacc578bfedced483d8c169ea5cb1777a99eea53)
    endif()
  # Download Tools
  elseif(VAR MATCHES "ARIA2")
    set(PROGNAME aria2c)
    set(PATHS ${DOWNLOADS}/tools/aria2c/aria2-1.34.0-win-32bit-build1)
    set(URL "https://github.com/aria2/aria2/releases/download/release-1.34.0/aria2-1.34.0-win-32bit-build1.zip")
    set(ARCHIVE "aria2-1.34.0-win-32bit-build1.zip")
    set(HASH 2a5480d503ac6e8203040c7e516a3395028520da05d0ebf3a2d56d5d24ba5d17630e8f318dd4e3cc2094cc4668b90108fb58e8b986b1ffebd429995058063c27)
  else()
    message(FATAL "unknown tool ${VAR} -- unable to acquire.")
  endif()

  macro(do_find)
    if(NOT DEFINED REQUIRED_INTERPRETER)
      find_program(${VAR} ${PROGNAME} PATHS ${PATHS} NO_DEFAULT_PATH)
      find_program(${VAR} ${PROGNAME})
    else()
      vcpkg_find_acquire_program(${REQUIRED_INTERPRETER})
      find_file(SCRIPT_${VAR} ${SCRIPTNAME} PATHS ${PATHS} NO_DEFAULT_PATH)
      find_file(SCRIPT_${VAR} ${SCRIPTNAME})
      set(${VAR} ${${REQUIRED_INTERPRETER}} ${SCRIPT_${VAR}})
    endif()
  endmacro()

  do_find()
  if("${${VAR}}" MATCHES "-NOTFOUND")
    if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" AND NOT _vfa_SUPPORTED)
      set(EXAMPLE ".")
      if(DEFINED BREW_PACKAGE_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        set(EXAMPLE ":\n    brew install ${BREW_PACKAGE_NAME}")
      elseif(DEFINED APT_PACKAGE_NAME AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        set(EXAMPLE ":\n    sudo apt-get install ${APT_PACKAGE_NAME}")
      endif()
      message(FATAL_ERROR "Could not find ${PROGNAME}. Please install it via your package manager${EXAMPLE}")
    endif()

    if(DEFINED SOURCEFORGE_ARGS)
      # Locally change editable to suppress re-extraction each time
      set(_VCPKG_EDITABLE 1)
      vcpkg_from_sourceforge(OUT_SOURCE_PATH SFPATH ${SOURCEFORGE_ARGS})
      unset(_VCPKG_EDITABLE)
    else()
      vcpkg_download_distfile(ARCHIVE_PATH
          URLS ${URL}
          SHA512 ${HASH}
          FILENAME ${ARCHIVE}
      )

      set(PROG_PATH_SUBDIR "${DOWNLOADS}/tools/${PROGNAME}/${SUBDIR}")
      file(MAKE_DIRECTORY ${PROG_PATH_SUBDIR})
      if(DEFINED NOEXTRACT)
        if(DEFINED _vfa_RENAME)
          file(INSTALL ${ARCHIVE_PATH} DESTINATION ${PROG_PATH_SUBDIR} RENAME ${_vfa_RENAME} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        else()
          file(COPY ${ARCHIVE_PATH} DESTINATION ${PROG_PATH_SUBDIR} FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        endif()
      else()
        get_filename_component(ARCHIVE_EXTENSION ${ARCHIVE} LAST_EXT)
        string(TOLOWER "${ARCHIVE_EXTENSION}" ARCHIVE_EXTENSION)
        if(ARCHIVE_EXTENSION STREQUAL ".msi")
          file(TO_NATIVE_PATH "${ARCHIVE_PATH}" ARCHIVE_NATIVE_PATH)
          file(TO_NATIVE_PATH "${PROG_PATH_SUBDIR}" DESTINATION_NATIVE_PATH)
          _execute_process(
            COMMAND msiexec /a ${ARCHIVE_NATIVE_PATH} /qn TARGETDIR=${DESTINATION_NATIVE_PATH}
            WORKING_DIRECTORY ${DOWNLOADS}
          )
        elseif("${ARCHIVE_PATH}" MATCHES ".7z.exe$")
          vcpkg_find_acquire_program(7Z)
          _execute_process(
            COMMAND ${7Z} x "${ARCHIVE_PATH}" "-o${PROG_PATH_SUBDIR}" -y -bso0 -bsp0
            WORKING_DIRECTORY ${PROG_PATH_SUBDIR}
          )
        else()
          _execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xzf ${ARCHIVE_PATH}
            WORKING_DIRECTORY ${PROG_PATH_SUBDIR}
          )
        endif()
      endif()
    endif()

    if(DEFINED POST_INSTALL_COMMAND)
      vcpkg_execute_required_process(
        ALLOW_IN_DOWNLOAD_MODE
        COMMAND ${POST_INSTALL_COMMAND}
        WORKING_DIRECTORY ${PROG_PATH_SUBDIR}
        LOGNAME ${VAR}-tool-post-install
      )
    endif()

    do_find()
  endif()

  set(${VAR} "${${VAR}}" PARENT_SCOPE)
endfunction()
