@echo on
set SCRIPT_DIR=%~dp0

set VCS_DIRECTORY=ign-sensors
set PLATFORM_TO_BUILD=x86_amd64
set IGN_CLEAN_WORKSPACE=true

set DEPEN_PKGS="cppzmq dlfcn-win32 gts freeimage ogre protobuf tinyxml2 zeromq"
set DEPEN_OSRF_PKGS="ogre2"
:: This needs to be migrated to DSL to get multi-major versions correctly
set COLCON_PACKAGE=ignition-sensors
set COLCON_AUTO_MAJOR_VERSION=true

call "%SCRIPT_DIR%\lib\colcon-default-devel-windows.bat"
