@echo on
set SCRIPT_DIR="%~dp0"

call "%SCRIPT_DIR%\lib\windows_configuration.bat"

set VCS_DIRECTORY=ign-msgs
set PLATFORM_TO_BUILD=x86_amd64
set IGN_CLEAN_WORKSPACE=true
set DEPEN_PKGS=protobuf-2.6.0-cmake3.5-win64-vc12.zip
set IGN_MATH_BRANCH=ign-math4

call "%SCRIPT_DIR%\lib\project-default-devel-windows.bat"
