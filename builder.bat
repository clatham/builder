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
rem  search for a BASH installation
rem

set "BASH_PATH_LIST="%ProgramFiles%\Git\bin\bash.exe" "%LocalAppData%\Programs\Git\bin\bash.exe" "%ProgramFiles(x86)%\Git\bin\bash.exe" "C:\msys64\usr\bin\bash.exe" "C:\cygwin64\bin\bash.exe" "C:\msys32\usr\bin\bash.exe" "C:\cygwin\bin\bash.exe""
set "BASH_PATH="

for %%P in (%BASH_PATH_LIST%) do (
    if exist %%P (
        set "BASH_PATH=%%~P"
        goto :found_bash
    )
)

echo.
echo BUILDER [error] could not find an installation of BASH
exit /b 1

:found_bash


rem
rem  determine the script directory
rem

set "SCRIPT_DIR=%~dp0"


rem
rem  invoke the builder script in git-bash
rem

"%BASH_PATH%" --login -c "%SCRIPT_DIR:\=/%/builder.sh %*"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo BUILDER [error] main script invocation failed
    exit /b %ERRORLEVEL%
)

exit /b 0
