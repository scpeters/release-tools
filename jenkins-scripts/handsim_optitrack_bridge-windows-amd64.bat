@echo on

set SCRIPT_DIR=%~dp0
set PLATFORM_TO_BUILD=amd64

call %SCRIPT_DIR%/lib/handsim_optitrack_bridge-base-windows.bat
