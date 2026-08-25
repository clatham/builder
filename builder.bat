@echo off
setlocal enabledelayedexpansion


rem
rem  determine whether msvc is already in the path
rem

if defined VCINSTALLDIR (
    goto :found_compiler
)


rem
rem  search for an msvc installation
rem

set "VERSIONS=2026 2022 2019 2017"
set "EDITIONS=Community Professional Enterprise BuildTools"
set "VCVARSALL_PATH="

for %%R in ("C:\Program Files", "C:\Program Files (x86)") do (
    for %%V in (%VERSIONS%) do (
        for %%E in (%EDITIONS%) do (
            set "TEST_PATH=%%~R\Microsoft Visual Studio\%%V\%%E\VC\Auxiliary\Build\vcvarsall.bat"

            if exist "!TEST_PATH!" (
                set "VCVARSALL_PATH=!TEST_PATH!"
                goto :found_vcvars
            )
        )
    )
)

echo.
echo BUILDER [error] could not find an installation of VS Studio
exit /b 1

:found_vcvars


rem
rem  call vcvarsall.bat
rem

call "%VCVARSALL_PATH%" x64

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo BUILDER [error] vcvarsall.bat invocation failed
    exit /b %ERRORLEVEL%
)

:found_compiler


rem
rem  determine the script directory
rem

set "SCRIPT_DIR=%~dp0"


rem
rem  invoke the builder script in git-bash
rem

"C:\Program Files\Git\bin\bash.exe" --login -c "%SCRIPT_DIR:\=/%/builder.sh %*"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo BUILDER [error] main script invocation failed
    exit /b %ERRORLEVEL%
)

exit /b 0
