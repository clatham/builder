#!/bin/bash


#
#  report error, and exits with code from $?
#  argument: $LINENO
#

builder_exit_on_error()
{
    local exit_code=$?
    
    echo -e ""
    echo -e "BUILDER [${RED}error${RESET}] failed at line ${BASH_LINENO[0]} with exit code ${exit_code}"
    
    exit "$exit_code"
}


#
#  report error with message
#  argument: a text string containing the error
#

builder_exit_with_message()
{
    echo -e ""
    echo -e "BUILDER [${RED}error${RESET}] $1"
    
    exit 1
}


#
#  get operating system name
#

builder_get_os()
{
    case "$(uname -s)" in
    
        CYGWIN* | MINGW* | MSYS*)
            echo "win"
            ;;
        
        Linux*)
            echo $(. /etc/os-release; echo "${ID}")
            ;;
        
        *)
            builder_exit_with_message "unsupported operating system: $(uname -s)"
            ;;
    
    esac
}


#
#  get operating system name and version
#

builder_get_os_and_version()
{
    case "$(uname -s)" in
    
        CYGWIN* | MINGW* | MSYS*)
            local build_number=$(powershell.exe -Command "[System.Environment]::OSVersion.Version.Build" | tr -d '\r')
            
            if [ "$build_number" -ge 22000 ]; then
                echo "win11"
            elif [ "$build_number" -ge 10240 ]; then
                echo "win10"
            elif [ "$build_number" -ge 9600 ]; then
                echo "win8.1"
            elif [ "$build_number" -ge 9200 ]; then
                echo "win8"
            elif [ "$build_number" -ge 7000 ]; then
                echo "win7"
            else
                builder_exit_with_message "unsupported windows version: build ${build_number}"
            fi
            ;;
        
        Linux*)
            echo $(. /etc/os-release; echo "${ID}${VERSION_ID}")
            ;;
        
        *)
            builder_exit_with_message "unsupported operating system: $(uname -s)"
            ;;
    
    esac
}


#
#  get compiler name and version
#

builder_get_compiler_and_version()
{
    case "$(uname -s)" in
        
        CYGWIN* | MINGW* | MSYS*)
            if ! command -v cl.exe &> /dev/null; then
                builder_exit_with_message "msvc compiler must be present in the path"
            fi
            
            local toolset_version=$(cl.exe 2>&1)
            toolset_version="${toolset_version##*Compiler Version }"
            toolset_version="${toolset_version%% *}"
            
            local major_version="${toolset_version%%.*}"
            
            local minor_version="${toolset_version#*.}"
            minor_version="${minor_version%%.*}"
            
            if [ "$major_version" -eq 19 ]; then
                if [ "$minor_version" -ge 50 ]; then
                    echo "msvc145"  # Visual Studio 2026
                elif [ "$minor_version" -ge 30 ]; then
                    echo "msvc143"  # Visual Studio 2022
                elif [ "$minor_version" -ge 20 ]; then
                    echo "msvc142"  # Visual Studio 2019
                else
                    builder_exit_with_message "unsupported msvc minor version: ${minor_version}"
                fi
            else
                builder_exit_with_message "unsupported msvc major version: ${major_version}"
            fi
            ;;
        
        Linux*)
            echo "gcc$(gcc -dumpversion)"
            ;;
        
        *)
            builder_exit_with_message "unsupported operating system: $(uname -s)"
            ;;
        
    esac
}


#
#  get architecture
#

builder_get_architecture()
{
    case "$(uname -m)" in
        
        x86_64 | amd64)
            echo "x64"
            ;;
        
        i386 | i686)
            echo "x86"
            ;;
        
        aarch64 | arm64)
            echo "arm64"
            ;;
        
        *)
            builder_exit_with_message "unsupported machine architecture: $(uname -s)"
            ;;
        
    esac
}


#
#  get cmake architecture
#

builder_get_cmake_architecture()
{
    case "$(builder_get_architecture)" in
        
        x64)
            echo "x64"
            ;;
        
        x86)
            echo "Win32"
            ;;
        
        arm64)
            echo "ARM64"
            ;;
        
        *)
            builder_exit_with_message "unsupported architecture: $(builder_get_architecture)"
            ;;
        
    esac
}


#
#  get cmake generator name
#

builder_get_cmake_generator()
{
    case "$(builder_get_compiler_and_version)" in
        
        msvc145)
            echo "Visual Studio 18 2026"
            ;;
        
        msvc143)
            echo "Visual Studio 17 2022"
            ;;
        
        msvc142)
            echo "Visual Studio 16 2019"
            ;;
        
        gcc*)
            echo "Unix Makefiles"
            ;;
        
        *)
            builder_exit_with_message "unsupported compiler and version: $(builder_get_compiler_and_version)"
            ;;
        
    esac
}


#
#  get vcpkg triplet
#

builder_get_vcpkg_triplet()
{
    case "$(uname -s)" in
        
        CYGWIN* | MINGW* | MSYS*)
            echo "$(builder_get_cmake_architecture)-windows"
            ;;
        
        Linux*)
            echo "$(builder_get_cmake_architecture)-linux"
            ;;
        
        *)
            builder_exit_with_message "unsupported operating system: $(uname -s)"
            ;;
        
    esac
}


#
#  prints the usage, and exits
#

print_usage()
{
    echo -e ""
    echo -e "Usage:"
    echo -e "    builder [options...]"
    echo -e "    builder --help"
    echo -e ""
    echo -e "Options:"
    echo -e "    --build-dir DIR"
    echo -e "        Sets the output directory to DIR (default=build)."
    echo -e "    -c, --config CONFIG"
    echo -e "        Sets the build configuration to CONFIG (default=Debug)."
    echo -e "    -d, --diagnostics"
    echo -e "        Prints the value of important functions and all variables."
    echo -e "    -h, -?, --help"
    echo -e "        Prints this usage, and exits."
    echo -e "    --install-dir DIR"
    echo -e "        Sets the install directory to DIR (default=install)."
    echo -e "    -j, --thread-count COUNT"
    echo -e "        Sets the number of threads to COUNT (default=80% of max)."
    echo -e "    -n, --no-build"
    echo -e "        Disables building of the project."
    echo -e "    --no-color"
    echo -e "        Disables ANSI/VT-100 color in text output."
    echo -e "    --no-vcpkg"
    echo -e "        Disables installation of packages with vcpkg."
    echo -e "    -p, --package"
    echo -e "        Packages the project."
    echo -e "    -r, --rebuild"
    echo -e "        Rebuilds the project."
    echo -e "    -t, --test"
    echo -e "        Tests the project."
    echo -e "    --test-dir DIR"
    echo -e "        Sets the test directory to DIR (default=tests)."
    echo -e "    --vcpkg-dir DIR"
    echo -e "        Sets the vcpkg directory to DIR (default=vcpkg)."
    echo -e "    --vcpkg-triplet TRIPLET"
    echo -e "        Sets the vcpkg triplet to TRIPLET (default=<architecture>-<os>)."

    exit 1
}


#
#  set up error handling
#

shopt -s extdebug

set -e  # exit on failed commands
set -o pipefail  # exit on failures within piped commands
set -E  # ensure functions inherit the ERR trap
trap builder_exit_on_error ERR


#
#  set up default configuration variables
#

BUILDER_BUILD_CONFIG=Debug
BUILDER_BUILD_DIR_DEBUG="debug"
BUILDER_BUILD_DIR_RELEASE="release"

BUILDER_CMAKE_TOOL="cmake"

BUILDER_COLORED_TEXT=1

BUILDER_INSTALL_DIR="install"

BUILDER_TEST_DIR="tests"

BUILDER_THREAD_COUNT=$(( $(nproc) * 8 / 10 ))

BUILDER_VCPKG_DIR="vcpkg"
BUILDER_VCPKG_FLAGS=
BUILDER_VCPKG_TRIPLET="$(builder_get_vcpkg_triplet)"

BUILDER_PERFORM_DIAG=0
BUILDER_PERFORM_VCPKG=1
BUILDER_PERFORM_REBUILD=0
BUILDER_PERFORM_BUILD=1
BUILDER_PERFORM_TEST=0
BUILDER_PERFORM_PACKAGE=0


#
#  overwrite default variables with values from builder.conf
#

if [ -f "builder.conf" ]; then
    source builder.conf
fi


#
#  process command line arguments
#

while [[ $# -gt 0 ]]; do
    case "$1" in
        
        --build-dir)
            BUILDER_BUILD_DIR=$2
            shift 2
            ;;
        
        -c | --config)
            BUILDER_BUILD_CONFIG=$2
            shift 2
            ;;
        
        -d | --diagnostics)
            BUILDER_PERFORM_DIAG=1
            shift 1
            ;;
        
        -h | -'?' | --help)
            print_usage
            shift 1
            ;;
        
        --install-dir)
            BUILDER_INSTALL_DIR=$2
            shift 2
            ;;
        
        -j | --thread-count)
            BUILDER_THREAD_COUNT=$2
            shift 2
            ;;
        
        -n | --no-build)
            BUILDER_PERFORM_BUILD=0
            shift 1
            ;;
        
        --no-color)
            BUILDER_COLORED_TEXT=0
            shift 1
            ;;
        
        --no-vcpkg)
            BUILDER_PERFORM_VCPKG=0
            shift 1
            ;;
        
        -p | --package)
            BUILDER_PERFORM_PACKAGE=1
            shift 1
            ;;
        
        -r | --rebuild)
            BUILDER_PERFORM_REBUILD=1
            shift 1
            ;;
        
        -t | --test)
            BUILDER_PERFORM_TEST=1
            shift 1
            ;;
        
        --test-dir)
            BUILDER_TEST_DIR=$2
            shift 2
            ;;
        
        --vcpkg-dir)
            BUILDER_VCPKG_DIR=$2
            shift 2
            ;;
        
        --vcpkg-triplet)
            BUILDER_VCPKG_TRIPLET=$2
            shift 2
            ;;
        
        *)
            builder_exit_with_message "unexpected argument: $1"
            exit 1
            ;;
        
    esac
done


#
#  if our output is a terminal, colored text is enabled, and more than eight
#  colors are supported, then setup the ANSI/VT-100 color codes
#

if [ -t 1 ]  &&  (( BUILDER_COLORED_TEXT )); then
    
    NUM_COLORS=$(tput colors 2>/dev/null)

    if [ "$NUM_COLORS" -ge 8 ]; then
        
        #  setup ANSI/VT100 codes
        
        BLACK="\e[30m"
        RED="\e[31m"
        GREEN="\e[32m"
        YELLOW="\e[33m"
        BLUE="\e[34m"
        MAGENTA="\e[35m"
        CYAN="\e[36m"
        WHITE="\e[37m"
        
        BRIGHT_BLACK="\e[90m"
        BRIGHT_RED="\e[91m"
        BRIGHT_GREEN="\e[92m"
        BRIGHT_YELLOW="\e[93m"
        BRIGHT_BLUE="\e[94m"
        BRIGHT_MAGENTA="\e[95m"
        BRIGHT_CYAN="\e[96m"
        BRIGHT_WHITE="\e[97m"
        
        RESET="\e[0m"
        
    fi
fi


#
#  display banner
#

echo -e ""
echo -e "${GREEN}BUILDER Build Tool${RESET}"
echo -e "Copyright (c) 2026 C. Latham.  All rights reserved."


#
#  set up working variables now, so they cannot be overidden
#

if [ -z "$BUILDER_BUILD_DIR" ]; then
    declare -n BUILDER_BUILD_DIR="BUILDER_BUILD_DIR_${BUILDER_BUILD_CONFIG^^}"
fi

if [ $BUILDER_THREAD_COUNT -lt 1 ]; then
    
    echo -e ""
    echo -e "BUILDER [${BRIGHT_YELLOW}warning${RESET}] thread count cannot be less than one -- setting it to one"
    
    BUILDER_THREAD_COUNT=1
    
fi

if [ ! -d "$BUILDER_VCPKG_DIR" ]; then
    
    echo -e ""
    echo -e "BUILDER [${BRIGHT_YELLOW}warning${RESET}] vcpkg directory does not exist -- vcpkg will be disabled"
    
    BUILDER_PERFORM_VCPKG=0
    
fi

if (( BUILDER_PERFORM_PACKAGE ))  &&  (( ! $BUILDER_PERFORM_BUILD ))  &&  [ ! -f "$BUILDER_BUILD_DIR/CMakeCache.txt" ]; then
    
    echo -e ""
    echo -e "BUILDER [${BRIGHT_YELLOW}warning${RESET}] building is disabled, and there is no build system -- packaging will be disabled"
    
    BUILDER_PERFORM_PACKAGE=0
    
fi


#
#  determine the number of steps to perform
#

BUILDER_STEP_COUNT=0
BUILDER_STEP=1

if (( BUILDER_PERFORM_DIAG )); then
    (( ++BUILDER_STEP_COUNT ))
fi

if (( BUILDER_PERFORM_VCPKG )); then
    (( ++BUILDER_STEP_COUNT ))
fi

if (( BUILDER_PERFORM_REBUILD )); then
    (( ++BUILDER_STEP_COUNT ))
fi

if(( BUILDER_PERFORM_BUILD )); then
    (( ++BUILDER_STEP_COUNT ))
fi

if (( BUILDER_PERFORM_TEST )); then
    (( ++BUILDER_STEP_COUNT ))
fi

if (( BUILDER_PERFORM_PACKAGE )); then
    (( ++BUILDER_STEP_COUNT ))
fi


#
#  if requested, print all functions and variables
#

if (( BUILDER_PERFORM_DIAG )); then
    
    echo -e ""
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] collecting diagnostics..."
    
    for func in $(declare -F | awk '{print $3}' | grep '^builder_get_'); do
        echo -e "${func}() = \"$($func)\""
    done
    
    echo -e ""
    
    for var in $(compgen -v BUILDER_); do
        echo -e "${var} = \"${!var}\""
    done
    
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] collecting diagnostics...done!"
    (( ++BUILDER_STEP ))
    
fi


#
#  if requested, pull dependencies with vcpkg
#

if (( BUILDER_PERFORM_VCPKG )); then
    
    echo -e ""
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] installing dependencies..."
    
    if ! command -v "$BUILDER_VCPKG_DIR/vcpkg" &> /dev/null; then
        
        if [ "$(builder_get_os)" == "win" ]; then
            cmd.exe //c "call $BUILDER_VCPKG_DIR\\bootstrap-vcpkg.bat -disableMetrics"
        else
            source "$BUILDER_VCPKG_DIR/bootstrap-vcpkg.sh -disableMetrics"
        fi
        
    fi
    
    "$BUILDER_VCPKG_DIR/vcpkg" install --triplet="$BUILDER_VCPKG_TRIPLET" --vcpkg-root="$(pwd)/$BUILDER_VCPKG_DIR" $BUILDER_VCPKG_FLAGS
    
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] installing dependencies...done!"
    (( ++BUILDER_STEP ))
    
fi


#
#  if requested, build the project
#

if (( BUILDER_PERFORM_BUILD )); then
    
    #  create the build directory, if required
    if [ ! -d "$BUILDER_BUILD_DIR" ]; then
        mkdir -p "$BUILDER_BUILD_DIR"
    fi
    
    #  if requested, remove the build directory contents
    if (( BUILDER_PERFORM_REBUILD )); then
        
        echo -e ""
        echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] removing existing build..."
        
        rm -rf "$BUILDER_BUILD_DIR"/*
        
        echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] removing existing build...done!"
        (( ++BUILDER_STEP ))
        
    fi
    
    echo -e ""
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] building project binaries..."
    
    #  generate the build system, if required
    if [ ! -f "$BUILDER_BUILD_DIR/CMakeCache.txt" ]; then
        "$BUILDER_CMAKE_TOOL" -S "." -B "$BUILDER_BUILD_DIR" -G "$(builder_get_cmake_generator)" -A "$(builder_get_cmake_architecture)"
    fi
    
    "$BUILDER_CMAKE_TOOL" --build "$BUILDER_BUILD_DIR" --config "$BUILDER_BUILD_CONFIG"
    
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] building project binaries...done!"
    (( ++BUILDER_STEP ))
    
fi


#
#  if requested, test the project
#

if (( BUILDER_PERFORM_TEST )); then
    
    echo -e ""
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] running test suite..."
    
    find "$BUILDER_BUILD_DIR/$BUILDER_TEST_DIR" -type f -executable -print0 \( -iname "*.exe" -o ! -name "*.*" \) | while read -r -d '' file; do
        echo "$file"
    done
    
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] running test suite...done!"
    (( ++BUILDER_STEP ))
    
fi


#
#  if requested, package the project
#

if (( BUILDER_PERFORM_PACKAGE )); then
    
    echo -e ""
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] building distribution package..."
    
    "$BUILDER_CMAKE_TOOL" --install "$BUILDER_BUILD_DIR" --config "$BUILDER_BUILD_CONFIG" --prefix "$BUILDER_BUILD_DIR/$BUILDER_INSTALL_DIR"
    "$BUILDER_CMAKE_TOOL" --build "$BUILDER_BUILD_DIR" --target package
    
    echo -e "BUILDER [${GREEN}${BUILDER_STEP}/${BUILDER_STEP_COUNT}${RESET}] building distribution package...done!"
    (( ++BUILDER_STEP ))

fi


#
#  report success
#

echo -e ""
echo -e "BUILDER [${GREEN}success${RESET}] completed successfully"

exit 0
