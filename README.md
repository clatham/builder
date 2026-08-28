# BUILDER Build Tool

## Overview

CMake is a powerful tool, but I get tired of invoking it to generate a project
build system, run the project build system, perform tests, install, and package
the project.  Each step is an opportunity to make a mistake.

BUILDER is a BASH tool for standard workflows built around CMake projects.  It
requires a BASH shell to run.  On Windows, you can install Git-BASH, MSYS, or
Cygwin.


## Table of Contents

- [Overview](#overview)
- [Table of Contents](#table-of-contents)
- [Operation](#operation)
- [Options](#options)
- [Config File](#config-file)
- [License](#license)


## Operation

Most commonly you would add BUILDER to your project as a submodule, so you can
keep up-to-date with features and bug fixes.  If you don't want to use a
submodule, you can copy it into a directory somewhere in your project, but
please include the `LICENSE` file and this `README.md` file.

On Windows, change to your project directory, and run `builder.bat`.  It's
important that the current directory contains the top-most `CMakeLists.txt`
file.

If `VCINSTALLDIR` is set because you're using a Visual Studio Developer Command
Prompt, then BUILDER will use that to access `cl.exe`.  If not, then BUILDER
will search for a Visual Studio installation on your system starting with the
most recent version, and it will invoke `vcvarsall.bat` to make `cl.exe`
available.

BUILDER will then search for an installation of BASH, including Git-BASH, MSYS,
and Cygwin.  It will prefer 64-bit to 32-bit.  Once one is found, it will be
used to run `builder.sh`.

On Linux, change to your project directory, and directly run `builder.sh`.

BUILDER can perform the following operations, depending upon configuration:

- Diagnostics

    BUILDER will optionally collect and display the name and values of all
    functions and environment variables to help you diagnose any build issues.

- Dependencies

    BUILDER will optionally install dependencies by invoking vcpkg from the
    `BUILDER_VCPKG_DIR` directory.

- Rebuild

    BUILDER will optionally remove the current CMake build system from the
    `BUILDER_BUILD_DIR` directory.

- Build

    If the build system does not currently exist, BUILDER will invoke CMake to
    generate it in the `BUILDER_BUILD_DIR` directory.  BUILDER will invoke CMake
    from the `BUILDER_CMAKE_TOOL` path to execute the build system, unless you
    disable it.

- Test

    BUILDER will optionally search the `BUILDER_TEST_DIR` directory, and it will
    run any executables (.exe files on Windows, and binaries with no extension
    on Linux) it finds.

- Package

    BUILDER will optionally use the `BUILDER_CMAKE_TOOL` path to build the
    `install` and `package` targets of your project, resulting in a compressed
    distribution package.


## Options

The following command-line options are available to tailor the operation of
BUILDER:

- --build-dir `DIR`

    Sets the output directory to `DIR` (default=`"build"`).

- -c, --config `CONFIG`

    Sets the build configuration to `CONFIG` (default=`Debug`).

- -d, --diagnostics

    Prints the value of important functions and all variables.

- -h, -?, --help

    Prints this usage, and exits.

- --install-dir `DIR`

    Sets the install directory to `DIR` (default=`"install"`).

- -j, --thread-count `COUNT`

    Sets the number of threads to `COUNT` (default=80% of max).

- -n, --no-build

    Disables building of the project.

- --no-color

    Disables ANSI/VT-100 color in text output.

- --no-vcpkg

    Disables installation of packages with vcpkg.

- -p, --package

    Packages the project.

- -r, --rebuild

    Rebuilds the project.

- -t, --test

    Tests the project.

- --test-dir `DIR`

    Sets the test directory to `DIR` (default=`"tests"`).

- --vcpkg-dir `DIR`

    Sets the vcpkg directory to `DIR` (default=`"vcpkg"`).

- --vcpkg-triplet `TRIPLET`

    Sets the vcpkg triplet to `TRIPLET` (default=`<architecture>-<os>`).


## Config File

If your project directory contains a file named "builder.conf", BUILDER will use
the variables provided within to configure itself.  The following variables may
be provided in the configuration file:

- BUILDER_BUILD_CONFIG

    Sets the CMake build configuration (default=`Debug`).

- BUILDER_BUILD_DIR_DEBUG

    Sets the build directory to use for `Debug` configurations (default=`"debug"`).

- BUILDER_BUILD_DIR_RELEASE

    Sets the build directory to use for `Release` configurations
    (default=`"release"`).

- BUILDER_CMAKE_TOOL

    Sets the path to the CMake tool (default=`"cmake"`).

- BUILDER_COLORED_TEXT

    Enables the use of ANSI/VT-100 color codes in text output (default=`1`).

- BUILDER_INSTALL_DIR

    Sets the installation directory to use (default=`"install"`).

- BUILDER_TEST_DIR

    Sets the test directory to use (default=`"tests"`).

- BUILDER_THREAD_COUNT

    Sets the number of threads to use when building (default=80% of available
    threads).

- BUILDER_VCPKG_DIR

    Sets the vcpkg directory to use (default=`"vcpkg"`).

- BUILDER_VCPKG_FLAGS

    Sets the flags to use when invoking vcpkg (default=`""`).

- BUILDER_VCPKG_TRIPLET

    Sets the triplet to use when invoking vcpkg (default=`"<architecture>-<os>"`).

- BUILDER_PERFORM_DIAG

    Enables the collection of diagnostics (default=`0`).

- BUILDER_PERFORM_VCPKG

    Enables the installing of dependencies with vcpkg (default=`1`).

- BUILDER_PERFORM_CLEAN

    Enables the removal and regeneration of the build system (default=`0`).

- BUILDER_PERFORM_BUILD

    Enables the building of the project (default=`1`).

- BUILDER_PERFORM_TEST

    Enables the execution of executables within the test directory (default=`0`).

- BUILDER_PERFORM_PACKAGE

    Enables the packaging of the project (default=`0`).


## License

BUILDER is licensed under the MIT license.  See the `LICENSE` file for the full
license.
